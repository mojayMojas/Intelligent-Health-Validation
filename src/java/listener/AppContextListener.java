package listener;

import listener.ReminderScheduler;
import javax.servlet.ServletContextEvent;
import javax.servlet.ServletContextListener;
import javax.servlet.annotation.WebListener;

@WebListener
public class AppContextListener implements ServletContextListener {

    @Override
    public void contextInitialized(ServletContextEvent sce) {
    
       
    }

    @Override
    public void contextDestroyed(ServletContextEvent sce) {
     
    }

 /*   
    @Override
    public void contextInitialized(ServletContextEvent sce) {
        System.out.println("=== IHVS Application Starting ===");
        ReminderScheduler.getInstance().start();
        System.out.println("=== Reminder Scheduler Started ===");
    }

    @Override
    public void contextDestroyed(ServletContextEvent sce) {
        System.out.println("=== IHVS Application Shutting Down ===");
        ReminderScheduler.getInstance().stop();
    }
*/
}