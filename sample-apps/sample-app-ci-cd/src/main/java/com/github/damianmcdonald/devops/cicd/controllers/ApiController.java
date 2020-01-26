package com.github.damianmcdonald.devops.cicd.controllers;

import com.github.damianmcdonald.devops.cicd.domain.Greeting;
import com.github.damianmcdonald.devops.cicd.service.GreetingService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.io.IOException;

@RestController
@RequestMapping("/api")
public class ApiController {

    @Autowired
    private GreetingService greetingService;

    @GetMapping(path = "/greeting")
    public Greeting greeting() throws IOException {
        return greetingService.getGreeting();
    }

}
