package ca.neitsch.intellij.reflow.blockcomment;

import com.google.common.collect.ImmutableList;
import org.junit.Test;

import static org.junit.Assert.*;

public class CCommentTest {
    private Codec _c = new CComment();

    @Test
    public void testComment() {
        _c.setBlockToBeDecoded(ImmutableList.of(
                "    /* foo",
                "     * bar */"));
        assertTrue(_c.detect());
        // The interface anticipates that trailing comment characters will be
        // stripped, but since we don’t need it yet, we don’t add it.
        assertEquals(ImmutableList.of(" foo", " bar */"),
                _c.innerContents());
        assertEquals(5, _c.getWrapWidth());
        assertEquals(ImmutableList.of(
                "    /* foo bar",
                "     * baz"),
                _c.apply(ImmutableList.of("foo bar", "baz")));
    }

    @Test
    public void testNonApplicableComment() {
        _c.setBlockToBeDecoded(ImmutableList.of("foo", "bar"));
        assertFalse(_c.detect());
    }
}
