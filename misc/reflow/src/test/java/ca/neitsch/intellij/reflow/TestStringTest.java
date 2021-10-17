package ca.neitsch.intellij.reflow;

import org.junit.Test;

import static org.junit.Assert.assertEquals;

public class TestStringTest {
    @Test
    public void testOneLine() {
        StringWithSelection s = new TestString("f[o]o");
        assertEquals(1, s.getStartPos());
        assertEquals(2, s.getEndPos());
        assertEquals("o", s.getSelection());
        assertEquals("foo", s.getString());
    }
}
