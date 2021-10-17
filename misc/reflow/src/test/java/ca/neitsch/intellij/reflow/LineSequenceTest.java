package ca.neitsch.intellij.reflow;

import com.google.common.collect.ImmutableList;
import org.junit.Test;

import static org.junit.Assert.assertEquals;

public class LineSequenceTest {
    @Test
    public void testLineSequence() {
        StringWithSelection s = new TestString("foo\nba[r\nbaz\nq]ux\nxyz");
        LineSequence ls = new LineSequence(s);

        assertEquals("bar", ls.getFirstLineWithSelection());
        assertEquals("qux", ls.getLastLineWithSelection());
        assertEquals(ImmutableList.of("bar", "baz", "qux"),
                ls.getSelectedLines());
        assertEquals(4, ls.getFirstLineStartPos());
        assertEquals(16, ls.getLastLineEndPos());
    }

    @Test
    public void testLineSequenceTrailingNewline() {
        StringWithSelection s = new TestString("foo\n[bar\n]baz");
        LineSequence ls = new LineSequence(s);
        assertEquals(ImmutableList.of("bar"), ls.getSelectedLines());
    }

    @Test
    public void testLineSequenceNoTrailingNewline() {
        StringWithSelection s = new TestString("foo\n[bar\nb]az");
        LineSequence ls = new LineSequence(s);
        assertEquals(s.getString().length(), ls.getLastLineEndPos());
    }
}
