package util;

import dao.AppointmentDAO;
import dao.ReminderDAO;
import model.Appointment;
import model.Reminder;

import javax.servlet.ServletContextEvent;
import javax.servlet.ServletContextListener;
import javax.servlet.annotation.WebListener;
import java.util.List;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.TimeUnit;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

/**
 * Background scheduler that runs every 5 minutes, finds due reminders,
 * and sends notifications.
 */
@WebListener
public class ReminderScheduler implements ServletContextListener {

    private ScheduledExecutorService executor;
    private static final DateTimeFormatter TIME_FORMATTER = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");
    private static final String SEPARATOR_LINE = "============================================================";

    @Override
    public void contextInitialized(ServletContextEvent sce) {
        executor = Executors.newSingleThreadScheduledExecutor();
        executor.scheduleAtFixedRate(this::processReminders, 1, 5, TimeUnit.MINUTES);
        System.out.println("[ReminderScheduler] Started — checking every 5 minutes at " + 
                          LocalDateTime.now().format(TIME_FORMATTER));
    }

    @Override
    public void contextDestroyed(ServletContextEvent sce) {
        if (executor != null) {
            executor.shutdownNow();
            try {
                if (!executor.awaitTermination(10, TimeUnit.SECONDS)) {
                    System.err.println("[ReminderScheduler] Executor did not terminate properly");
                }
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
            }
        }
        System.out.println("[ReminderScheduler] Stopped");
    }

    private void processReminders() {
        System.out.println("[ReminderScheduler] Checking for pending reminders at " + 
                          LocalDateTime.now().format(TIME_FORMATTER));
        
        ReminderDAO reminderDAO = new ReminderDAO();
        AppointmentDAO apptDAO = new AppointmentDAO();
        
        // Get pending reminders that are due
        List<Reminder> pending = reminderDAO.getPendingReminders();
        
        if (pending == null || pending.isEmpty()) {
            System.out.println("[ReminderScheduler] No pending reminders found");
            return;
        }
        
        System.out.println("[ReminderScheduler] Found " + pending.size() + " pending reminder(s)");
        
        for (Reminder r : pending) {
            if (r == null) continue;
            
            try {
                // Get appointment details
                Appointment apt = apptDAO.getAppointmentById(r.getAppointmentId());
                
                if (apt == null) { 
                    System.err.println("[ReminderScheduler] Appointment not found for reminder #" + r.getReminderId());
                    reminderDAO.markReminderAsFailed(r.getReminderId());
                    continue; 
                }
                
                // Skip if appointment was cancelled or completed
                String aptStatus = apt.getStatus();
                if ("cancelled".equals(aptStatus) || "completed".equals(aptStatus) || "no-show".equals(aptStatus)) {
                    System.out.println("[ReminderScheduler] Skipping reminder #" + r.getReminderId() + 
                                     " - appointment status: " + aptStatus);
                    reminderDAO.markReminderAsFailed(r.getReminderId());
                    continue;
                }
                
                // Send the reminder
                boolean sent = sendReminder(r, apt);
                
                if (sent) {
                    reminderDAO.markReminderAsSent(r.getReminderId());
                    AuditLogger.log(apt.getPatientId(), "REMINDER_SENT",
                            "Appointment #" + apt.getAppointmentId() + " | " + r.getReminderType() + 
                            " reminder sent to " + apt.getPatientEmail(),
                            "scheduler");
                    System.out.println("[ReminderScheduler] Successfully sent reminder #" + r.getReminderId());
                } else {
                    reminderDAO.markReminderAsFailed(r.getReminderId());
                    System.err.println("[ReminderScheduler] Failed to send reminder #" + r.getReminderId());
                }
                
            } catch (Exception e) {
                System.err.println("[ReminderScheduler] Failed to process reminder #" + 
                                  (r != null ? r.getReminderId() : "unknown") + ": " + e.getMessage());
                e.printStackTrace();
                
                if (r != null) {
                    try {
                        reminderDAO.markReminderAsFailed(r.getReminderId());
                    } catch (Exception ex) {
                        System.err.println("[ReminderScheduler] Could not mark reminder as failed: " + ex.getMessage());
                    }
                }
            }
        }
    }

    /**
     * Send reminder via email/SMS
     * Returns true if sent successfully
     */
    private boolean sendReminder(Reminder reminder, Appointment apt) {
        if (reminder == null || apt == null) return false;
        
        try {
            String patientName = apt.getPatientName() != null ? apt.getPatientName() : "Patient";
            String doctorName = apt.getDoctorName() != null ? apt.getDoctorName() : "your doctor";
            String appointmentDate = apt.getAppointmentDate() != null ? apt.getAppointmentDate() : "scheduled date";
            String appointmentTime = apt.getAppointmentTime() != null ? apt.getAppointmentTime() : "scheduled time";
            
            String when = "24h".equals(reminder.getReminderType()) ? "tomorrow" : "in 1 hour";
            
            String subject = "[IHVS REMINDER] Your appointment is " + when;
            String msg = String.format(
                "Dear %s,\n\n" +
                "This is a reminder that your appointment with %s on %s at %s is %s.\n\n" +
                "Please attend on time or cancel at least 2 hours in advance to avoid affecting your reliability score.\n\n" +
                "Thank you,\nIHVS System",
                patientName, doctorName, appointmentDate, appointmentTime, when);

            // TODO: Replace with actual email/SMS implementation
            // For email: Use JavaMail API
            // For SMS: Use Twilio or similar service
            
            // Print to console for demonstration
            System.out.println("\n" + SEPARATOR_LINE);
            System.out.println("📧 REMINDER (" + reminder.getReminderType() + ")");
            System.out.println("To: " + apt.getPatientEmail());
            System.out.println("Subject: " + subject);
            System.out.println(repeatChar('-', 60));
            System.out.println(msg);
            System.out.println(SEPARATOR_LINE + "\n");
            
            // Simulate successful sending
            // In production, replace with actual email sending code:
            /*
            // Example using JavaMail:
            Properties props = new Properties();
            props.put("mail.smtp.host", "smtp.gmail.com");
            props.put("mail.smtp.port", "587");
            props.put("mail.smtp.auth", "true");
            props.put("mail.smtp.starttls.enable", "true");
            
            Session session = Session.getInstance(props, new Authenticator() {
                protected PasswordAuthentication getPasswordAuthentication() {
                    return new PasswordAuthentication("sender@ihvs.com", "password");
                }
            });
            
            Message message = new MimeMessage(session);
            message.setFrom(new InternetAddress("noreply@ihvs.com"));
            message.setRecipients(Message.RecipientType.TO, InternetAddress.parse(apt.getPatientEmail()));
            message.setSubject(subject);
            message.setText(msg);
            Transport.send(message);
            */
            
            return true;
            
        } catch (Exception e) {
            System.err.println("[ReminderScheduler] Failed to send reminder: " + e.getMessage());
            return false;
        }
    }
    
    /**
     * Helper method to repeat a character for Java 8 compatibility
     * This replaces String.repeat() which is only available in Java 11+
     */
    private String repeatChar(char ch, int count) {
        StringBuilder sb = new StringBuilder(count);
        for (int i = 0; i < count; i++) {
            sb.append(ch);
        }
        return sb.toString();
    }
}