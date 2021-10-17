package ca.neitsch.intellij.reflow;

/**
 * For testing, a string with ‘[’ ‘]’ selection markers that are parsed out and returned.
 */
public class TestString
    implements StringWithSelection
{
    private StringWithSelection _o;

    public TestString(String s) {
        int startPos = s.indexOf('[');
        int endPos = s.indexOf(']');

        s = s.substring(0, startPos)
                + s.substring(startPos + 1, endPos)
                + s.substring(endPos + 1);

        // We ate the ‘[’ character that marked the start of input, so
        // subsequent indices need to be decremented.
        endPos -= 1;

        _o = new DefaultStringWithSelection(s, startPos, endPos);
    }

    @Override
    public String getString() {
        return _o.getString();
    }

    @Override
    public int getStartPos() {
        return _o.getStartPos();
    }

    @Override
    public int getEndPos() {
        return _o.getEndPos();
    }

    @Override
    public String getSelection() {
        return _o.getSelection();
    }
}
