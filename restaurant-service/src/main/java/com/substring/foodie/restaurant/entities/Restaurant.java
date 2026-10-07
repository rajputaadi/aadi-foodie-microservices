package com.substring.foodie.restaurant.entities;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.time.LocalTime;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "restaurant")
@Getter
@Setter
public class Restaurant {
    @Id
    private String id;
    private String name;
    private String address;
    private String phone;
    // EAGER: open-in-view is off, so a lazy list can't be loaded while writing the JSON response
    @ElementCollection(fetch = FetchType.EAGER)
    private List<String> pictures = new ArrayList<>();

    // priority 1 open true ki false
    private boolean open = false;

    // priority 2
    private LocalTime openTime;
    private LocalTime closeTime;

    // TEXT instead of @Lob: on postgres @Lob maps to an oid large object,
    // which can't be read outside a transaction
    @Column(columnDefinition = "TEXT")
    private String aboutRestaurant;


}
