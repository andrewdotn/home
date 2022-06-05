package ca.neitsch.intellij.reflow;

import com.google.common.collect.ImmutableList;
import org.apache.commons.io.IOUtils;
import org.junit.Test;

import java.io.IOException;
import java.io.InputStream;
import java.util.List;

import static ca.neitsch.intellij.reflow.blockcomment.CommonPrefix.nonAlphabeticPrefix;
import static java.nio.charset.StandardCharsets.UTF_8;
import static org.apache.commons.lang.StringUtils.repeat;
import static org.junit.Assert.*;

public class TextFlowTest {
    private TextFlow _f = new TextFlow();

    @Test
    public void testNoReflowForShortStrings() {
        List<String> l = ImmutableList.of("foo bar baz");
        assertEquals(l.get(0) + "\n", _f.reflow(l));
    }

    @Test
    public void testReflowOneLongLine() {
        List<String> l = ImmutableList.of(repeat("foo ", 40));
        String expected = repeat(repeat("foo ", 19) + "foo\n", 2);
        assertEquals(expected, _f.reflow(l));
    }

    @Test
    public void testJava1() {
        assertCorrectReflow("Foo1.java");
    }

    @Test
    public void testJava2() {
        assertCorrectReflow("Foo2.java");
    }

    @Test
    public void testJava3() {
        assertCorrectReflow("Foo3.java");
    }

    @Test
    public void testAlphPrefix1() {
        assertCorrectReflow("AlphPrefix1.java");
    }

    @Test
    public void testMarkdown1() {
        assertCorrectReflow("Markdown1.java");
    }

    @Test
    public void testMarkdown2() {
        assertCorrectReflow("Markdown2.java");
    }

    @Test
    public void testRuby1() {
        assertCorrectReflow("foo1.rb");
    }

    @Test
    public void testRuby2() {
        assertCorrectReflow("foo2.rb");
    }

    @Test
    public void testGo1() {
        assertCorrectReflow("foo1.go");
    }

    @Test
    public void testGo2() {
        assertCorrectReflow("foo2.go");
    }


    @Test
    public void testReflow() {
        assertEquals(
                "The quick brown fox jumped\nover the lazy dogs",
                _f.balance("The\nquick brown fox jumped over the lazy dogs", 30));
    }

    @Test
    public void testNonAlphabeticPrefix() {
        assertEquals("   // ", nonAlphabeticPrefix("   // foo"));
    }

    private void assertCorrectReflow(String sampleFileName) {
        String expectedOutput = getTestFile(sampleFileName + ".out.txt");
        String rawInput = getTestFile(sampleFileName + ".in.txt");
        TestString s = new TestString(rawInput);
        LineSequence ls = new LineSequence(s);

        String output = _f.reflow(ls.getSelectedLines());

        String replacedOutput =
                s.getString().substring(0, ls.getFirstLineStartPos())
                        + output
                        + s.getString().substring(ls.getLastLineEndPos());

        assertEquals(expectedOutput, replacedOutput);
    }

    private String getTestFile(String path)
    {
        InputStream s = getClass().getResourceAsStream(path);
        if (s == null) {
            throw new RuntimeException("Resource with path " + path + " not found");
        }
        try {
            return IOUtils.toString(s, UTF_8);
        } catch (IOException e) {
            throw new RuntimeException(e);
        }
    }
}
