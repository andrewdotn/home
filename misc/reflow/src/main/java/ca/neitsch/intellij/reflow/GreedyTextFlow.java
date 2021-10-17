package ca.neitsch.intellij.reflow;

import com.google.common.base.Joiner;
import com.google.common.collect.Lists;

import java.util.List;
import java.util.regex.Pattern;

public class GreedyTextFlow {
    private static final Pattern RE_WS = Pattern.compile("\\s+");

    private String _s;
    private int _maxLength;

    private List<String> _out;
    private StringBuilder _curLine;

    public GreedyTextFlow(String s, int maxLength) {
        _s = s;
        _maxLength = maxLength;
    }

    public String getFlowed() {
        _out = Lists.newArrayList();
        _curLine = new StringBuilder();
        StringBuilder sb = new StringBuilder();

        RE_WS.splitAsStream(_s).forEach((w) -> addWord(w));

        endLine();

        return Joiner.on("\n").join(_out);
    }

    // Initial greedy implementation
    private void addWord(String w) {
        if (_curLine == null) {
            _curLine = new StringBuilder();
        }

        int spacerWidth = _curLine.length() == 0 ? 0 : 1;

        if (_curLine.length() + spacerWidth + w.length() > _maxLength) {
            endLine();
        }
        if (_curLine.length() != 0)
            _curLine.append(" ");
        _curLine.append(w);
    }

    private void endLine() {
        if (_curLine.length() != 0)
            _out.add(_curLine.toString());
        _curLine = new StringBuilder();
    }
}
