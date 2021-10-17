package ca.neitsch.intellij.reflow;

public class DefaultStringWithSelection
    implements StringWithSelection
{
    private String _s;
    private int _startPos;
    private int _endPos;

    public DefaultStringWithSelection(String s, int startPos, int endPos) {
      _s = s;
      _startPos = startPos;
      _endPos = endPos;
    }

    @Override
    public int getStartPos() {
        return _startPos;
    }

    @Override
    public int getEndPos() {
        return _endPos;
    }

    @Override
    public String getSelection() {
        return _s.substring(getStartPos(), getEndPos());
    }

    @Override
    public String getString() {
        return _s;
    }
}
