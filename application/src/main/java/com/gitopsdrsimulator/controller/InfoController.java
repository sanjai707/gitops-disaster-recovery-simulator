package com.gitopsdrsimulator.controller;

import com.gitopsdrsimulator.model.InfoResponse;
import java.net.InetAddress;
import java.net.UnknownHostException;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.env.Environment;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api")
public class InfoController {

    private final Environment environment;
    private final String applicationVersion;

    public InfoController(
            Environment environment,
            @Value("${application.version:dev}") String applicationVersion) {
        this.environment = environment;
        this.applicationVersion = applicationVersion;
    }

    @GetMapping("/info")
    public InfoResponse info() {
        return new InfoResponse(
                "gitops-dr-simulator",
                applicationVersion,
                activeProfile(),
                hostname());
    }

    private String activeProfile() {
        String[] activeProfiles = environment.getActiveProfiles();
        return activeProfiles.length == 0 ? "default" : String.join(",", activeProfiles);
    }

    private String hostname() {
        String configuredHostname = System.getenv("HOSTNAME");
        if (configuredHostname != null && !configuredHostname.isBlank()) {
            return configuredHostname;
        }

        try {
            return InetAddress.getLocalHost().getHostName();
        } catch (UnknownHostException exception) {
            return "unknown";
        }
    }
}
