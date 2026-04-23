package service;

import model.Appointment;
import model.User;
import util.DBConnection;

import javax.mail.*;
import javax.mail.internet.*;
import java.util.Properties;

public class EmailService {
    
    private static final String SMTP_HOST = "smtp.gmail.com";
    private static final String SMTP_PORT = "587";
    private static final String FROM_EMAIL = "ihvs@system.com";
    private static final String FROM_PASSWORD = "your_password";
    
    public static boolean sendAppointmentReminder(Appointment apt, User patient) {
        String subject = "Appointment Reminder - IHVS";
        String body = buildReminderEmail(apt, patient);
        
        return sendEmail(patient.getEmail(), subject, body);
    }
    
    private static String buildReminderEmail(Appointment apt, User patient) {
        return "Dear " + patient.getFullName() + ",\n\n" +
               "This is a reminder for your upcoming appointment:\n\n" +
               "Date: " + apt.getAppointmentDate() + "\n" +
               "Time: " + apt.getAppointmentTime() + "\n" +
               "Doctor: " + apt.getDoctorName() + "\n\n" +
               "Please arrive 15 minutes early.\n\n" +
               "Thank you,\n" +
               "IHVS System";
    }
    
    private static boolean sendEmail(String to, String subject, String body) {
        Properties props = new Properties();
        props.put("mail.smtp.host", SMTP_HOST);
        props.put("mail.smtp.port", SMTP_PORT);
        props.put("mail.smtp.auth", "true");
        props.put("mail.smtp.starttls.enable", "true");
        
        Session session = Session.getInstance(props, new Authenticator() {
            @Override
            protected PasswordAuthentication getPasswordAuthentication() {
                return new PasswordAuthentication(FROM_EMAIL, FROM_PASSWORD);
            }
        });
        
        try {
            Message message = new MimeMessage(session);
            message.setFrom(new InternetAddress(FROM_EMAIL));
            message.setRecipients(Message.RecipientType.TO, InternetAddress.parse(to));
            message.setSubject(subject);
            message.setText(body);
            
            Transport.send(message);
            return true;
        } catch (MessagingException e) {
            e.printStackTrace();
            return false;
        }
    }
}