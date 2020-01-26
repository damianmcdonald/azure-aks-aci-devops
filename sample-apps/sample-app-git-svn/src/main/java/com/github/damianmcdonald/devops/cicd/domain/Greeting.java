package com.github.damianmcdonald.devops.cicd.domain;

import org.apache.commons.codec.binary.Base64;
import org.apache.commons.io.IOUtils;
import org.springframework.core.io.ClassPathResource;

import java.io.IOException;

public class Greeting {

    private static final String IMAGE_PATH = "static/assets/images/";
    private static final String EXTENSION_PNG = ".png";

    private final String message;
    private final String flagImage;

    public Greeting(final String message, final String flagImage) throws IOException {
        this.message = message;
        this.flagImage = encodeImageBase64(flagImage);
    }

    private String encodeImageBase64(final String flagImage) throws IOException {
        final byte[] imageBytes = IOUtils.toByteArray(new ClassPathResource(buildImagePath(flagImage)).getInputStream());
        return new String(new Base64().encode(imageBytes));
    }

    private String buildImagePath(final String flagImage) {
        return IMAGE_PATH.concat(flagImage).concat(EXTENSION_PNG);
    }

    public String getMessage() {
        return message;
    }

    public String getFlagImage() {
        return flagImage;
    }
}
