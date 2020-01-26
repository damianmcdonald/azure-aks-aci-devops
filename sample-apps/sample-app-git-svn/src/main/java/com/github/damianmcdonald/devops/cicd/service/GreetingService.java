package com.github.damianmcdonald.devops.cicd.service;

import com.github.damianmcdonald.devops.cicd.domain.Greeting;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.io.IOException;

@Service
public class GreetingService {

    @Value("${greeting.message}")
    private String message;

    @Value("${greeting.flag.image}")
    private String flagImage;

    public Greeting getGreeting() throws IOException {
        return new Greeting(message, flagImage);
    }

}
