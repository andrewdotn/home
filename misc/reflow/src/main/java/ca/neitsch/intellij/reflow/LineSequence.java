package ca.neitsch.intellij.reflow;

import com.google.common.collect.ImmutableList;
import com.google.common.collect.Iterables;
import com.google.common.collect.Lists;

import java.util.List;

public class LineSequence {
    private StringWithSelection _s;
    private String _input;

    // Where we are while parsing lines; initiaily startPos
    private int _pointer;
    private List<String> _lines;

    private static final int UNSET = -1;

    private int _initialRemaining = UNSET;
    private int _firstLineStartPos = UNSET;
    private int _lastLineEndPos = UNSET;

    public LineSequence(StringWithSelection s) {
        _s = s;
        _input = _s.getString();

        _lines = Lists.newArrayList();
        _pointer = _s.getStartPos();

        while (_pointer < _s.getEndPos()) {
            addNextLine();
        }

        _lines = ImmutableList.copyOf(_lines);
    }

    private void addNextLine() {
        int lineStart = _input.lastIndexOf('\n', _pointer) + 1;

        if (lineStart == _s.getEndPos()) {
            _pointer = lineStart;
            return;
        }

        // No newline found?
        if (lineStart == -1)
            lineStart = 0;
        int lineEnd = _input.indexOf('\n', lineStart);
        if (lineEnd == -1)
            lineEnd = _input.length();

        // If the next two values are unset, we’re on the first line and can set
        // them.
        if (_firstLineStartPos == UNSET)
            _firstLineStartPos = lineStart;
        if (_initialRemaining == UNSET)
            _initialRemaining = _pointer - lineStart;

        String line = _input.substring(lineStart, lineEnd);
        _lines.add(line);

        // The end position comes *after* the trailing newline, if there is one.
        _lastLineEndPos = Math.min(lineEnd + 1, _input.length());

        _pointer = lineEnd;
    }

    public String getFirstLineWithSelection() {
        return _lines.get(0);
    }

    public String getLastLineWithSelection() {
        return Iterables.getLast(_lines);
    }

    public List<String> getSelectedLines() {
        return _lines;
    }

    /**
     * How many extra characters occur at the start of the first line before
     * the beginning of the selection.
     */
    public int getInitialRemaining() {
        return _initialRemaining;
    }

    /**
     * The StringWithSelection-relative position of the start of the first line
     * that intersects the selection.
     */
    public int getFirstLineStartPos() {
        return _firstLineStartPos;
    }

    /**
     * The StringWithSelection-relative position of the end of the last line that
     * intersects the selection.
     */
    public int getLastLineEndPos() {
        return _lastLineEndPos;
    }
}
