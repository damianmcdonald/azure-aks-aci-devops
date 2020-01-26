package com.github.damianmcdonald.devops.cicd.service;

import com.github.damianmcdonald.devops.cicd.domain.Greeting;
import org.apache.commons.codec.binary.Base64;
import org.junit.Assert;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.core.io.ClassPathResource;
import org.springframework.test.annotation.DirtiesContext;
import org.springframework.test.context.junit4.SpringRunner;

import java.io.File;
import java.io.IOException;
import java.nio.file.Files;

@RunWith(SpringRunner.class)
@SpringBootTest
@DirtiesContext(classMode = DirtiesContext.ClassMode.BEFORE_CLASS)
public class GreetingServiceUnitTest {

    private static final String IMAGE_PATH = "static/assets/images/";
    private static final String EXTENSION_PNG = ".png";

    @Value("${greeting.message}")
    private String message;

    @Value("${greeting.flag.image}")
    private String flagImage;

    @Autowired
    private GreetingService greetingService;

    @Test
    public void getGreetingTest() throws IOException {
        final Greeting greeting = greetingService.getGreeting();
        Assert.assertNotNull(greeting);
        Assert.assertEquals(message, greeting.getMessage());
        Assert.assertEquals(encodeImageBase64(), greeting.getFlagImage());
    }

    private String encodeImageBase64() throws IOException {
        final File imageFile = new ClassPathResource(buildImagePath(flagImage)).getFile();
        return new String(new Base64().encode(Files.readAllBytes(imageFile.toPath())));
    }

    private String buildImagePath(final String flagImage) {
        return IMAGE_PATH.concat(flagImage).concat(EXTENSION_PNG);
    }

}
