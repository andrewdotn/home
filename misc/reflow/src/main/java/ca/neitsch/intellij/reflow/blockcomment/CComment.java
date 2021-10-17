package ca.neitsch.intellij.reflow.blockcomment;

import com.google.common.base.Strings;
import com.google.common.collect.ImmutableList;
import com.google.common.collect.Lists;

import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class CComment
    implements Codec
{
    private static final Pattern INITIAL_C_COMMENT = Pattern.compile("^(\\s*)/\\*");
    private static final Pattern SUBSEQUENT_C_COMMENT = Pattern.compile("^(\\s*)\\*");

    private List<String> _lines;
    private List<String> _strippedLines;
    private int _width;

    @Override
    public void setBlockToBeDecoded(List<String> lines) {
        _lines = ImmutableList.copyOf(lines);
        clear();
    }

    private void clear() {
        _strippedLines = null;
        _width = Integer.MAX_VALUE;
    }

    @Override
    public boolean detect() {
        check();
        return _strippedLines != null;
    }

    @Override
    public List<String> innerContents() {
        check();
        return _strippedLines;
    }

    @Override
    public List<String> apply(List<String> modifiedLines) {
        List<String> ret = Lists.newArrayList();
        ret.add(Strings.repeat(" ", _width) + "/* " + modifiedLines.get(0));
        for (int i = 1; i < modifiedLines.size(); i++) {
            ret.add(Strings.repeat(" ", _width) + " * " + modifiedLines.get(i));
        }
        return ret;
    }

    @Override
    public int getWrapWidth() {
        check();
        // The incoming comment might not have a ‘ ’ after the ‘*’, but we always
        // add one in apply().
        return _width + 1;
    }

    private void check() {
        if (_strippedLines != null)
            return;

        _strippedLines = Lists.newArrayList();

        if (!pruneLineAndAdd(INITIAL_C_COMMENT, 0)) {
            clear();
            return;
        }

        for (int i = 1; i < _lines.size(); i++) {
            if (!pruneLineAndAdd(SUBSEQUENT_C_COMMENT, i)) {
              clear();
              return;
            }
        }
    }

    boolean pruneLineAndAdd(Pattern p, int i) {
        String line = _lines.get(i);
        Matcher m = p.matcher(line);
        if (!m.find())
            return false;

        _strippedLines.add(line.substring(m.end()));
        _width = Math.min(_width, m.group(1).length());

        return true;
    }
}
