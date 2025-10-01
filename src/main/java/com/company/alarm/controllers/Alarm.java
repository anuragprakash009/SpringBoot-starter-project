package com.company.alarm.controllers;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class Alarm {

    @GetMapping("/name")
    public String getName(){
        Map<String, String> map = new HashMap();
        map.put("Name", "anurag");

        List<String> list= new ArrayList<>();
        
        System.out.println(map);
        return "Anurag Prakash";
    }
}
