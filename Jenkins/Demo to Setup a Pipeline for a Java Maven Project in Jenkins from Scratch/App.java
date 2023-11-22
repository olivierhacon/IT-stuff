package com.mycompany.app;

public class App {
    public static void main(String[] args) {
        System.out.println("Starting CPU Load Application");

        while (true) {
            fibonacci(30); // Calculate the 30th Fibonacci number repeatedly
        }
    }

    public static long fibonacci(int n) {
        if (n <= 1) return n;
        else return fibonacci(n - 1) + fibonacci(n - 2);
    }
}
