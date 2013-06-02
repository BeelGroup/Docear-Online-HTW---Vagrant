import org.junit.Test;
import org.openqa.selenium.By;
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.WebElement;
import org.openqa.selenium.htmlunit.HtmlUnitDriver;

public class SeleniumTest {

    @Test
    public void testApplicationRunning() throws Exception {
        final WebDriver driver = new HtmlUnitDriver();
        driver.get("https://my.docear.org");
        assertLoginElementsPresent(driver);
    }

    private void assertLoginElementsPresent(WebDriver driver) {
        driver.findElement(By.id("username"));
        driver.findElement(By.id("password"));
    }
}
