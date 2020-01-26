package com.github.damianmcdonald.devops.cicd.controllers;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.github.damianmcdonald.devops.cicd.domain.Greeting;
import com.github.damianmcdonald.devops.cicd.service.GreetingService;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.mockito.Mockito;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.test.context.junit4.SpringRunner;
import org.springframework.test.web.servlet.MockMvc;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@RunWith(SpringRunner.class)
@WebMvcTest(ApiController.class)
public class ApiControllerUnitTest {

    @Value("${greeting.message}")
    private String message;

    @Value("${greeting.flag.image}")
    private String flagImage;

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private GreetingService greetingService;

    @Test
    public void greetingTest() throws Exception {
        Mockito.when(greetingService.getGreeting()).thenReturn(new Greeting(message, flagImage));
        this.mockMvc.perform(get("/api/greeting"))
                .andExpect(status().isOk())
                .andExpect(content().json(new ObjectMapper().writeValueAsString(new Greeting(message, flagImage))));
    }

}
