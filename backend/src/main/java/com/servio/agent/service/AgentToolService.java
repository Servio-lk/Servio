package com.servio.agent.service;

import com.servio.booking.dto.AppointmentDto;
import com.servio.booking.dto.AppointmentRequest;
import com.servio.booking.dto.VehicleDto;
import com.servio.booking.service.AppointmentService;
import com.servio.booking.service.VehicleService;
import com.servio.catalog.dto.ServiceResponse;
import com.servio.catalog.service.ServiceService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.*;

@Slf4j
@Service
@RequiredArgsConstructor
public class AgentToolService {

    private final VehicleService vehicleService;
    private final ServiceService serviceService;
    private final AppointmentService appointmentService;

    /**
     * Tool definitions in Gemini function declaration format
     */
    public List<Map<String, Object>> getToolDeclarations() {
        List<Map<String, Object>> functionDeclarations = new ArrayList<>();

        // 1. get_user_vehicles
        Map<String, Object> getUserVehicles = new LinkedHashMap<>();
        getUserVehicles.put("name", "get_user_vehicles");
        getUserVehicles.put("description", "Get the list of vehicles registered by the currently authenticated user, including make, model, year, and license plate.");
        getUserVehicles.put("parameters", Map.of(
                "type", "OBJECT",
                "properties", Collections.emptyMap()
        ));
        functionDeclarations.add(getUserVehicles);

        // 2. get_catalog_services
        Map<String, Object> getCatalogServices = new LinkedHashMap<>();
        getCatalogServices.put("name", "get_catalog_services");
        getCatalogServices.put("description", "Get all active vehicle services offered by Servio with names, descriptions, base prices (in LKR), and durations.");
        getCatalogServices.put("parameters", Map.of(
                "type", "OBJECT",
                "properties", Collections.emptyMap()
        ));
        functionDeclarations.add(getCatalogServices);

        // 3. get_service_details
        Map<String, Object> getServiceDetails = new LinkedHashMap<>();
        getServiceDetails.put("name", "get_service_details");
        getServiceDetails.put("description", "Get in-depth details, inclusions, and options for a specific service by its ID.");
        Map<String, Object> serviceDetailsProps = new LinkedHashMap<>();
        serviceDetailsProps.put("serviceId", Map.of(
                "type", "INTEGER",
                "description", "The unique ID of the service."
        ));
        getServiceDetails.put("parameters", Map.of(
                "type", "OBJECT",
                "properties", serviceDetailsProps,
                "required", List.of("serviceId")
        ));
        functionDeclarations.add(getServiceDetails);

        // 4. get_booked_slots
        Map<String, Object> getBookedSlots = new LinkedHashMap<>();
        getBookedSlots.put("name", "get_booked_slots");
        getBookedSlots.put("description", "Check unavailable/booked time slots for a specific date (YYYY-MM-DD) so you can propose available times to the customer.");
        Map<String, Object> bookedSlotsProps = new LinkedHashMap<>();
        bookedSlotsProps.put("date", Map.of(
                "type", "STRING",
                "description", "The target date in YYYY-MM-DD format (e.g. '2026-09-05')."
        ));
        getBookedSlots.put("parameters", Map.of(
                "type", "OBJECT",
                "properties", bookedSlotsProps,
                "required", List.of("date")
        ));
        functionDeclarations.add(getBookedSlots);

        // 5. book_appointment
        Map<String, Object> bookAppointment = new LinkedHashMap<>();
        bookAppointment.put("name", "book_appointment");
        bookAppointment.put("description", "Create a confirmed booking for a service appointment once the user agrees on the vehicle, service type, and slot.");
        Map<String, Object> bookProps = new LinkedHashMap<>();
        bookProps.put("serviceType", Map.of(
                "type", "STRING",
                "description", "The name or description of the service to book (e.g. 'Full Synthetic Oil Change')."
        ));
        bookProps.put("appointmentDate", Map.of(
                "type", "STRING",
                "description", "The appointment date and time in ISO-8601 format (e.g. '2026-09-05T10:00:00')."
        ));
        bookProps.put("vehicleId", Map.of(
                "type", "INTEGER",
                "description", "Optional vehicle ID chosen from get_user_vehicles."
        ));
        bookProps.put("notes", Map.of(
                "type", "STRING",
                "description", "Optional special notes or customer instructions."
        ));
        bookAppointment.put("parameters", Map.of(
                "type", "OBJECT",
                "properties", bookProps,
                "required", List.of("serviceType", "appointmentDate")
        ));
        functionDeclarations.add(bookAppointment);

        return functionDeclarations;
    }

    /**
     * Executes a tool invoked by Gemini within the authenticated user's security context.
     */
    public Object executeTool(String toolName, Map<String, Object> args, Authentication authentication) {
        log.info("Agent executing tool: {} with args: {}", toolName, args);
        try {
            switch (toolName) {
                case "get_user_vehicles":
                    return handleGetUserVehicles(authentication);

                case "get_catalog_services":
                    return handleGetCatalogServices();

                case "get_service_details":
                    return handleGetServiceDetails(args);

                case "get_booked_slots":
                    return handleGetBookedSlots(args);

                case "book_appointment":
                    return handleBookAppointment(args, authentication);

                default:
                    return Map.of("error", "Unknown tool: " + toolName);
            }
        } catch (Exception e) {
            log.error("Error executing tool {}: {}", toolName, e.getMessage(), e);
            return Map.of("error", e.getMessage() != null ? e.getMessage() : "Error executing tool");
        }
    }

    private Object handleGetUserVehicles(Authentication authentication) {
        List<VehicleDto> vehicles = vehicleService.getMyVehicles(authentication);
        if (vehicles.isEmpty()) {
            return Map.of("message", "User has no vehicles registered yet.");
        }
        List<Map<String, Object>> result = new ArrayList<>();
        for (VehicleDto v : vehicles) {
            Map<String, Object> item = new HashMap<>();
            item.put("id", v.getId());
            item.put("make", v.getMake());
            item.put("model", v.getModel());
            item.put("year", v.getYear());
            item.put("licensePlate", v.getLicensePlate());
            result.add(item);
        }
        return Map.of("vehicles", result);
    }

    private Object handleGetCatalogServices() {
        List<ServiceResponse> services = serviceService.getAllServices();
        List<Map<String, Object>> result = new ArrayList<>();
        for (ServiceResponse s : services) {
            Map<String, Object> item = new HashMap<>();
            item.put("id", s.getId());
            item.put("name", s.getName());
            item.put("description", s.getDescription());
            item.put("basePrice", s.getBasePrice());
            item.put("durationMinutes", s.getDurationMinutes());
            result.add(item);
        }
        return Map.of("services", result);
    }

    private Object handleGetServiceDetails(Map<String, Object> args) {
        Number idNum = (Number) args.get("serviceId");
        if (idNum == null) {
            return Map.of("error", "serviceId parameter is required");
        }
        ServiceResponse service = serviceService.getServiceById(idNum.longValue());
        return Map.of(
                "id", service.getId(),
                "name", service.getName(),
                "description", service.getDescription() != null ? service.getDescription() : "",
                "basePrice", service.getBasePrice() != null ? service.getBasePrice() : 0,
                "durationMinutes", service.getDurationMinutes() != null ? service.getDurationMinutes() : 60,
                "options", service.getOptions() != null ? service.getOptions() : Collections.emptyList()
        );
    }

    private Object handleGetBookedSlots(Map<String, Object> args) {
        String dateStr = (String) args.get("date");
        if (dateStr == null || dateStr.trim().isEmpty()) {
            return Map.of("error", "date parameter is required (format YYYY-MM-DD)");
        }
        LocalDate date = LocalDate.parse(dateStr.trim());
        List<String> bookedSlots = appointmentService.getBookedSlotsForDate(date);
        return Map.of(
                "date", dateStr,
                "bookedTimeslots", bookedSlots,
                "note", "Working hours are typically 08:30 to 17:30. Any slot not in bookedTimeslots is available."
        );
    }

    private Object handleBookAppointment(Map<String, Object> args, Authentication authentication) {
        String serviceType = (String) args.get("serviceType");
        String dateStr = (String) args.get("appointmentDate");
        Number vehicleIdNum = (Number) args.get("vehicleId");
        String notes = (String) args.get("notes");

        if (serviceType == null || dateStr == null) {
            return Map.of("error", "serviceType and appointmentDate are required to book an appointment");
        }

        LocalDateTime appointmentDate;
        try {
            appointmentDate = LocalDateTime.parse(dateStr.trim(), DateTimeFormatter.ISO_LOCAL_DATE_TIME);
        } catch (Exception e) {
            try {
                appointmentDate = LocalDateTime.parse(dateStr.trim());
            } catch (Exception e2) {
                return Map.of("error", "Invalid appointmentDate format. Please use ISO-8601 e.g. 2026-09-05T10:00:00");
            }
        }

        AppointmentRequest request = AppointmentRequest.builder()
                .serviceType(serviceType)
                .appointmentDate(appointmentDate)
                .vehicleId(vehicleIdNum != null ? vehicleIdNum.longValue() : null)
                .notes(notes != null ? notes : "Booked via Servio AI Assistant")
                .location("Servio Auto Care Main Workshop")
                .build();

        AppointmentDto created = appointmentService.createAppointment(request, authentication);
        return Map.of(
                "success", true,
                "appointmentId", created.getId(),
                "serviceType", created.getServiceType(),
                "appointmentDate", created.getAppointmentDate().toString(),
                "status", created.getStatus(),
                "message", "Appointment successfully booked!"
        );
    }
}
