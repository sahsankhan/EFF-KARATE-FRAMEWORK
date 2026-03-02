package Runners;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardOpenOption;
import java.util.stream.Stream;

/**
 * Standalone utility to enhance Karate reports with scenario counts
 * Layout: Feature boxes -> Scenario boxes -> "Scenarios" label
 */
public class ReportEnhancer {
    
    public static void main(String[] args) {
        try {
            Path reportsDir = Paths.get("target/karate-reports");
            if (!Files.exists(reportsDir)) {
                System.out.println("❌ Reports directory not found. Run tests first!");
                return;
            }
            
            // JavaScript with correct layout - Features in middle, Scenarios at bottom
            String customJS = "(function() {\n" +
                "    function addScenarioBoxes() {\n" +
                "        try {\n" +
                "            const table = document.querySelector('.features-table tbody');\n" +
                "            if (!table) return;\n" +
                "            \n" +
                "            let totalPassedScenarios = 0;\n" +
                "            let totalFailedScenarios = 0;\n" +
                "            \n" +
                "            const rows = table.querySelectorAll('tr');\n" +
                "            rows.forEach(row => {\n" +
                "                const cells = row.querySelectorAll('td');\n" +
                "                if (cells.length >= 5) {\n" +
                "                    totalPassedScenarios += parseInt(cells[2].textContent.trim()) || 0;\n" +
                "                    totalFailedScenarios += parseInt(cells[3].textContent.trim()) || 0;\n" +
                "                }\n" +
                "            });\n" +
                "            \n" +
                "            const navCount = document.querySelector('.nav-count');\n" +
                "            const existingPass = document.getElementById('nav-pass');\n" +
                "            const existingFail = document.getElementById('nav-fail');\n" +
                "            \n" +
                "            if (navCount && existingPass && existingFail && !document.getElementById('scenarios-added')) {\n" +
                "                \n" +
                "                // Add spacing to existing feature boxes\n" +
                "                existingPass.style.marginBottom = '2px';\n" +
                "                existingFail.style.marginBottom = '2px';\n" +
                "                \n" +
                "                // Add Features label AFTER feature boxes (in middle)\n" +
                "                const featuresLabel = document.createElement('div');\n" +
                "                featuresLabel.textContent = 'Features';\n" +
                "                featuresLabel.style.cssText = 'font-size: 11px; color: #999; text-align: center; text-transform: uppercase; font-weight: 600; letter-spacing: 1px; margin: 10px 0 15px 0;';\n" +
                "                navCount.appendChild(featuresLabel);\n" +
                "                \n" +
                "                // Create scenario boxes with identical styling\n" +
                "                const passedBox = document.createElement('div');\n" +
                "                passedBox.className = existingPass.className;\n" +
                "                \n" +
                "                // Copy all attributes\n" +
                "                for (let i = 0; i < existingPass.attributes.length; i++) {\n" +
                "                    const attr = existingPass.attributes[i];\n" +
                "                    if (attr.name !== 'id') {\n" +
                "                        passedBox.setAttribute(attr.name, attr.value);\n" +
                "                    }\n" +
                "                }\n" +
                "                \n" +
                "                // Copy exact styling\n" +
                "                const passedStyles = window.getComputedStyle(existingPass);\n" +
                "                passedBox.style.height = passedStyles.height;\n" +
                "                passedBox.style.minHeight = passedStyles.minHeight;\n" +
                "                passedBox.style.padding = passedStyles.padding;\n" +
                "                passedBox.style.fontSize = passedStyles.fontSize;\n" +
                "                passedBox.style.fontWeight = passedStyles.fontWeight;\n" +
                "                passedBox.style.fontFamily = passedStyles.fontFamily;\n" +
                "                passedBox.style.lineHeight = passedStyles.lineHeight;\n" +
                "                passedBox.style.textAlign = passedStyles.textAlign;\n" +
                "                passedBox.style.display = passedStyles.display;\n" +
                "                passedBox.style.alignItems = passedStyles.alignItems;\n" +
                "                passedBox.style.justifyContent = passedStyles.justifyContent;\n" +
                "                passedBox.style.boxSizing = passedStyles.boxSizing;\n" +
                "                passedBox.style.marginBottom = '2px';\n" +
                "                \n" +
                "                passedBox.textContent = totalPassedScenarios;\n" +
                "                \n" +
                "                // Same for failed box\n" +
                "                const failedBox = document.createElement('div');\n" +
                "                failedBox.className = existingFail.className;\n" +
                "                \n" +
                "                for (let i = 0; i < existingFail.attributes.length; i++) {\n" +
                "                    const attr = existingFail.attributes[i];\n" +
                "                    if (attr.name !== 'id') {\n" +
                "                        failedBox.setAttribute(attr.name, attr.value);\n" +
                "                    }\n" +
                "                }\n" +
                "                \n" +
                "                const failedStyles = window.getComputedStyle(existingFail);\n" +
                "                failedBox.style.height = failedStyles.height;\n" +
                "                failedBox.style.minHeight = failedStyles.minHeight;\n" +
                "                failedBox.style.padding = failedStyles.padding;\n" +
                "                failedBox.style.fontSize = failedStyles.fontSize;\n" +
                "                failedBox.style.fontWeight = failedStyles.fontWeight;\n" +
                "                failedBox.style.fontFamily = failedStyles.fontFamily;\n" +
                "                failedBox.style.lineHeight = failedStyles.lineHeight;\n" +
                "                failedBox.style.textAlign = failedStyles.textAlign;\n" +
                "                failedBox.style.display = failedStyles.display;\n" +
                "                failedBox.style.alignItems = failedStyles.alignItems;\n" +
                "                failedBox.style.justifyContent = failedStyles.justifyContent;\n" +
                "                failedBox.style.boxSizing = failedStyles.boxSizing;\n" +
                "                \n" +
                "                failedBox.textContent = totalFailedScenarios;\n" +
                "                \n" +
                "                // Add scenario boxes\n" +
                "                navCount.appendChild(passedBox);\n" +
                "                navCount.appendChild(failedBox);\n" +
                "                \n" +
                "                // Add Scenarios label at the very bottom\n" +
                "                const scenariosLabel = document.createElement('div');\n" +
                "                scenariosLabel.textContent = 'Scenarios';\n" +
                "                scenariosLabel.style.cssText = 'font-size: 11px; color: #999; text-align: center; text-transform: uppercase; font-weight: 600; letter-spacing: 1px; margin: 10px 0 0 0;';\n" +
                "                navCount.appendChild(scenariosLabel);\n" +
                "                \n" +
                "                // Mark as done\n" +
                "                const marker = document.createElement('div');\n" +
                "                marker.id = 'scenarios-added';\n" +
                "                marker.style.display = 'none';\n" +
                "                document.body.appendChild(marker);\n" +
                "                \n" +
                "                console.log('Perfect layout: Feature boxes -> Features label -> Scenario boxes -> Scenarios label');\n" +
                "            }\n" +
                "        } catch (error) {\n" +
                "            console.error('Error:', error);\n" +
                "        }\n" +
                "    }\n" +
                "    \n" +
                "    if (document.readyState === 'loading') {\n" +
                "        document.addEventListener('DOMContentLoaded', addScenarioBoxes);\n" +
                "    } else {\n" +
                "        addScenarioBoxes();\n" +
                "    }\n" +
                "})();";
            
            // Process HTML files
            try (Stream<Path> files = Files.walk(reportsDir)) {
                long enhanced = files.filter(path -> path.toString().endsWith(".html"))
                     .peek(htmlFile -> enhanceHtmlFile(htmlFile, customJS))
                     .count();
                
                System.out.println("Enhanced " + enhanced + " files - Features in middle, Scenarios at bottom");
                System.out.println("Refresh report for perfect layout!");
            }
            
        } catch (IOException e) {
            System.err.println("Error: " + e.getMessage());
        }
    }
    
    private static void enhanceHtmlFile(Path htmlFile, String customJS) {
        try {
            String content = Files.readString(htmlFile);
            
            // Clean up any previous versions
            content = content.replaceAll("<script[^>]*>\\s*\\(function\\(\\)[\\s\\S]*?\\}\\)\\(\\);\\s*</script>", "");
            
            // Skip if already enhanced
            if (content.contains("scenarios-added")) {
                return;
            }
            
            String jsInjection = "    <script>\n" + customJS + "\n    </script>\n  </body>";
            String enhancedContent = content.replace("</body>", jsInjection);
            
            Files.writeString(htmlFile, enhancedContent, StandardOpenOption.TRUNCATE_EXISTING);
            
        } catch (IOException e) {
            System.err.println("Error: " + htmlFile + " - " + e.getMessage());
        }
    }
}