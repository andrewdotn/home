package ca.neitsch.intellij.reflow.blockcomment;

import com.google.common.collect.ImmutableList;
import com.google.common.collect.Streams;

import java.util.ArrayList;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.stream.Collectors;
import java.util.stream.Stream;

import static com.google.common.base.Strings.commonPrefix;

public class CommonPrefix
    implements Codec
{
    private static Pattern RE_NON_ALPHA = Pattern.compile("^[^\\p{IsAlphabetic}]*");

    private List<String> _lines;
    private String _prefix;
    private boolean _addSpace = false;
    private boolean _isMarkdownBullet = false;

    public static String nonAlphabeticPrefix(String s) {
        Matcher m = RE_NON_ALPHA.matcher(s);
        if (m.find() && m.start() == 0) {
            return s.substring(0, m.end());
        }
        return "";
    }

    @Override
    public void setBlockToBeDecoded(List<String> lines) {
        _lines = ImmutableList.copyOf(lines);
        _prefix = null;
    }

    @Override
    public boolean detect() {
        // The common prefix codec is always applicable, even when the common
        // prefix ends up being a degenerate 0-length string.
        return true;
    }

    @Override
    public List<String> innerContents() {
        computePrefix();

        List<String> ret = new ArrayList<>();
        for (String line: _lines) {
            if (_isMarkdownBullet
                    && (line.startsWith(_prefix + "  ")
                        || line.startsWith(_prefix + "- ")))
            {
                ret.add(line.substring(_prefix.length() + 2));
            } else {
                ret.add(line.substring(_prefix.length()));
            }
        }
        return ret;
    }

    private boolean lineIsPartOfMarkdownList(String line) {
        return line.startsWith(_prefix + "- ") || line.startsWith(_prefix + "  ");
    }

    @Override
    public List<String> apply(List<String> modifiedLines) {

        List<String> ret = new ArrayList<>();

        boolean first = true;
        for (String s: modifiedLines) {
            if (s.equals(_prefix)) {
                ret.add(_prefix);
            } else if (_addSpace) {
                ret.add(_prefix + " " + s);
            } else if (_isMarkdownBullet && first) {
                first = false;
                ret.add(_prefix + "- " + s);
            } else if (_isMarkdownBullet && !first) {
                ret.add(_prefix + "  " + s);
            } else {
                ret.add(_prefix + s);
            }
        }
        return ret;
    }

    @Override
    public int getWrapWidth() {
        computePrefix();

        var tabCount = _prefix.codePoints()
                .filter(i -> i == Character.valueOf('\t'))
                .count();

        return _prefix.length()
                // 7 because each 8-char tab already counted as taking 1 space
                + 7 * (int)tabCount
                // for markdown bullet lists, we add back two chars later
                + (_isMarkdownBullet ? 2 : 0);
    }

    /** Identify a common prefix, e.g., a comment delimiter */
    private void computePrefix() {
        if (_prefix != null)
            return;

        if (_lines.size() > 1) {
            _prefix = _lines.get(0);
            for (String s: _lines) {
                _prefix = commonPrefix(_prefix, s);
            }
            _prefix = nonAlphabeticPrefix(_prefix);
        } else {
            _prefix = nonAlphabeticPrefix(_lines.get(0));
        }

        // The common prefix may have an optional space that isn’t detected
        // because blank lines omit it.
        //
        // ^ like this
        _addSpace = true;
        for (String s: _lines) {
            if (s.length() > _prefix.length() && !s.startsWith(_prefix + " "))
                _addSpace = false;
        }

        if (_prefix.endsWith("  - ")) {
            _isMarkdownBullet = true;
            _prefix = _prefix.substring(0, _prefix.length() - 2);
        } else if (_prefix.endsWith("  ")
                && _lines.stream().allMatch(this::lineIsPartOfMarkdownList)) {
            _isMarkdownBullet = true;
        }
    }
}
