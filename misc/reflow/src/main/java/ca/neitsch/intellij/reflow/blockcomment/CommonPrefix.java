package ca.neitsch.intellij.reflow.blockcomment;

import com.google.common.collect.ImmutableList;

import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.stream.Collectors;

import static com.google.common.base.Strings.commonPrefix;

public class CommonPrefix
    implements Codec
{
    private static Pattern RE_NON_ALPHA = Pattern.compile("^(.*?)(?=\\p{IsAlphabetic})");

    private List<String> _lines;
    private String _prefix;
    private boolean _addSpace = false;

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
        return _lines.stream().map(s -> s.substring(_prefix.length()))
                .collect(Collectors.toList());
    }

    @Override
    public List<String> apply(List<String> modifiedLines) {
        return modifiedLines.stream().map(s -> {
            if (s.equals(_prefix)) {
                return _prefix;
            }
            if (_addSpace) {
                return _prefix + " " + s;
            }
            return _prefix + s;
        }).collect(Collectors.toList());
    }

    @Override
    public int getWrapWidth() {
        computePrefix();
        return _prefix.length();
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
    }
}
