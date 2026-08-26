package com.gitopsdrsimulator.controller;

import com.gitopsdrsimulator.model.ReadinessResponse;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api")
public class ReadinessController {

    @GetMapping("/ready")
    public ReadinessResponse ready() {
        return new ReadinessResponse("UP", "Application is ready; database integration is deferred.");
    }
}
