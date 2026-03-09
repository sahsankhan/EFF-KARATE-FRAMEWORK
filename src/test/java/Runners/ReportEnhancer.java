package Runners;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardOpenOption;
import java.util.stream.Stream;
import java.util.List;
import java.util.ArrayList;
import java.util.regex.Pattern;
import java.util.regex.Matcher;

/**
 * Standalone utility to enhance Karate reports with scenario counts
 * Layout: Feature boxes -> Scenario boxes -> "Scenarios" label
 */
public class ReportEnhancer {
    
    /**
     * Extracts the feature execution order from TestRunner.java
     */
    private static List<String> extractFeatureOrderFromTestRunner() {
        List<String> featureOrder = new ArrayList<>();
        try {
            Path testRunnerPath = Paths.get("src/test/java/Runners/TestRunner.java");
            if (!Files.exists(testRunnerPath)) {
                System.out.println("TestRunner.java not found. Using fallback order.");
                return featureOrder;
            }
            
            String content = Files.readString(testRunnerPath);
            
            // Pattern to match "classpath:..." paths in the Karate.run() method
            Pattern pattern = Pattern.compile("\"classpath:([^\"]+\\.feature)\"");
            Matcher matcher = pattern.matcher(content);
            
            while (matcher.find()) {
                String featurePath = matcher.group(1);
                // Convert classpath format to report format (remove classpath: prefix)
                featureOrder.add(featurePath);
            }
            
            System.out.println("Extracted " + featureOrder.size() + " features from TestRunner.java");
            
        } catch (IOException e) {
            System.err.println("Error reading TestRunner.java: " + e.getMessage());
        }
        
        return featureOrder;
    }
    
    /**
     * Builds a JavaScript array string from the feature order list
     */
    private static String buildJavaScriptArray(List<String> features) {
        if (features.isEmpty()) {
            return "[]";
        }
        
        StringBuilder sb = new StringBuilder("[");
        for (int i = 0; i < features.size(); i++) {
            if (i > 0) sb.append(",");
            sb.append("'").append(features.get(i)).append("'");
        }
        sb.append("]");
        return sb.toString();
    }
    
    public static void main(String[] args) {
        try {
            Path reportsDir = Paths.get("target/karate-reports");
            if (!Files.exists(reportsDir)) {
                System.out.println("Reports directory not found. Run tests first!");
                return;
            }
            
            // Extract feature order from TestRunner.java
            List<String> dynamicOrder = extractFeatureOrderFromTestRunner();
            String orderArray = buildJavaScriptArray(dynamicOrder);
            
            // JavaScript with correct layout - Features in middle, Scenarios at bottom
            String customJS = "(function() {\n" +
                "    function reorderFeatures() {\n" +
                "        try {\n" +
                "            console.log('Starting feature reordering...');\n" +
                "            \n" +
                "            // Reorder main features table\n" +
                "            const mainTable = document.querySelector('.features-table tbody');\n" +
                "            if (mainTable) {\n" +
                "                console.log('Reordering main features table');\n" +
                "                reorderTable(mainTable);\n" +
                "            }\n" +
                "            \n" +
                "            // Reorder tags table if it exists (try multiple selectors)\n" +
                "            const tagSelectors = ['.table-condensed tbody', '.table tbody', '#tags .table tbody', '[role=\"tabpanel\"] .table tbody'];\n" +
                "            let tagsTable = null;\n" +
                "            for (const selector of tagSelectors) {\n" +
                "                tagsTable = document.querySelector(selector);\n" +
                "                if (tagsTable && tagsTable.closest('#tags, [aria-labelledby=\"tags-tab\"]')) {\n" +
                "                    console.log('Found tags table with selector:', selector);\n" +
                "                    break;\n" +
                "                }\n" +
                "            }\n" +
                "            if (tagsTable) {\n" +
                "                console.log('Reordering tags table');\n" +
                "                reorderTable(tagsTable);\n" +
                "            } else {\n" +
                "                console.log('Tags table not found - trying alternative approach');\n" +
                "                setTimeout(() => reorderTagsTableAlternative(), 500);\n" +
                "            }\n" +
                "            \n" +
                "            // Also set up observers for tab switching\n" +
                "            setupTabObserver();\n" +
                "            \n" +
                "        } catch (e) {\n" +
                "            console.error('Error in reorderFeatures:', e);\n" +
                "        }\n" +
                "    }\n" +
                "    \n" +
                "    function reorderTable(table) {\n" +
                "        try {\n" +
                "            \n" +
                "            const order = __DYNAMIC_ORDER__;\n" +
                "            \n" +
                "            const rows = Array.from(table.querySelectorAll('tr'));\n" +
                "            console.log('Found', rows.length, 'rows in table');\n" +
                "            \n" +
                "            const featureMap = {};\n" +
                "            rows.forEach(row => {\n" +
                "                const cell = row.querySelector('td');\n" +
                "                if (cell) {\n" +
                "                    const featureName = cell.textContent.trim();\n" +
                "                    featureMap[featureName] = row;\n" +
                "                }\n" +
                "            });\n" +
                "            \n" +
                "            table.innerHTML = '';\n" +
                "            \n" +
                "            let reorderedCount = 0;\n" +
                "            order.forEach(feature => {\n" +
                "                if (featureMap[feature]) {\n" +
                "                    table.appendChild(featureMap[feature]);\n" +
                "                    delete featureMap[feature];\n" +
                "                    reorderedCount++;\n" +
                "                }\n" +
                "            });\n" +
                "            \n" +
                "            // Add any remaining features\n" +
                "            Object.values(featureMap).forEach(row => table.appendChild(row));\n" +
                "            \n" +
                "            console.log('Reordered', reorderedCount, 'features in this table');\n" +
                "        } catch (e) {\n" +
                "            console.error('Error reordering table:', e);\n" +
                "        }\n" +
                "    }\n" +
                "    \n" +
                "    function reorderTagsTableAlternative() {\n" +
                "        try {\n" +
                "            console.log('Trying alternative tags table detection...');\n" +
                "            // Look for any table that might be the tags table\n" +
                "            const allTables = document.querySelectorAll('table tbody');\n" +
                "            for (const table of allTables) {\n" +
                "                const firstRow = table.querySelector('tr');\n" +
                "                if (firstRow) {\n" +
                "                    const firstCell = firstRow.querySelector('td');\n" +
                "                    if (firstCell && firstCell.textContent.includes('.feature')) {\n" +
                "                        console.log('Found potential tags table, attempting reorder...');\n" +
                "                        reorderTable(table);\n" +
                "                        table.setAttribute('data-reordered', 'true');\n" +
                "                        break;\n" +
                "                    }\n" +
                "                }\n" +
                "            }\n" +
                "        } catch (e) {\n" +
                "            console.error('Error in alternative tags table reordering:', e);\n" +
                "        }\n" +
                "    }\n" +
                "    \n" +
                "    function setupTabObserver() {\n" +
                "        try {\n" +
            "            // Watch for tab clicks with better timing\n" +
                "            const tabs = document.querySelectorAll('a[href=\"#tags\"], a[href=\"#summary\"], [data-toggle=\"tab\"]');\n" +
                "            tabs.forEach(tab => {\n" +
                "                tab.addEventListener('click', (event) => {\n" +
                "                    const isTagsTab = tab.getAttribute('href') === '#tags' || tab.textContent.toLowerCase().includes('tags');\n" +
                "                    const delay = isTagsTab ? 500 : 200; // Extra delay for tags tab\n" +
                "                    setTimeout(() => {\n" +
                "                        console.log('Tab switched to:', isTagsTab ? 'tags' : 'other', 'reordering tables...');\n" +
                "                        reorderFeatures();\n" +
                "                        if (isTagsTab) {\n" +
                "                            // Extra attempt for tags\n" +
                "                            setTimeout(() => reorderTagsTableAlternative(), 300);\n" +
                "                        }\n" +
                "                    }, delay);\n" +
                "                });\n" +
                "            });\n" +
                "            \n" +
                "            // Also use MutationObserver to catch dynamic table changes\n" +
                "            const observer = new MutationObserver((mutations) => {\n" +
                "                // Check for tags tables with multiple selectors\n" +
                "                const tagSelectors = ['.table-condensed tbody', '.table tbody', '#tags .table tbody', '[role=\"tabpanel\"] .table tbody'];\n" +
                "                for (const selector of tagSelectors) {\n" +
                "                    const tagsTable = document.querySelector(selector);\n" +
                "                    if (tagsTable && !tagsTable.hasAttribute('data-reordered')) {\n" +
                "                        // Check if this is actually a tags table by looking for .feature files\n" +
                "                        const firstRow = tagsTable.querySelector('tr td');\n" +
                "                        if (firstRow && firstRow.textContent.includes('.feature')) {\n" +
                "                            setTimeout(() => {\n" +
                "                                console.log('New tags table detected with selector:', selector);\n" +
                "                                reorderTable(tagsTable);\n" +
                "                                tagsTable.setAttribute('data-reordered', 'true');\n" +
                "                            }, 100);\n" +
                "                            break;\n" +
                "                        }\n" +
                "                    }\n" +
                "                }\n" +
                "            });\n" +
                "            \n" +
                "            observer.observe(document.body, {\n" +
                "                childList: true,\n" +
                "                subtree: true\n" +
                "            });\n" +
                "            \n" +
                "        } catch (e) {\n" +
                "            console.error('Error setting up tab observer:', e);\n" +
                "        }\n" +
                "    }\n" +
                "    \n" +
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
                "            }\n" +
                "        } catch (error) {\n" +
                "            console.error('Error:', error);\n" +
                "        }\n" +
                "    }\n" +
                "    \n" +
                "    function enhance() {\n" +
                "        // Add a small delay to ensure table is fully rendered\n" +
                "        setTimeout(() => {\n" +
                "            reorderFeatures();\n" +
                "            addScenarioBoxes();\n" +
                "            \n" +
                "            // Recheck periodically for dynamically loaded content\n" +
                "            setTimeout(() => {\n" +
                "                console.log('Performing periodic check for tables...');\n" +
                "                reorderFeatures();\n" +
                "                reorderTagsTableAlternative();\n" +
                "            }, 1000);\n" +
                "            \n" +
                "            // Additional periodic check specifically for tags\n" +
                "            setInterval(() => {\n" +
                "                const allTables = document.querySelectorAll('table tbody');\n" +
                "                let foundUnorderedTagsTable = false;\n" +
                "                for (const table of allTables) {\n" +
                "                    if (!table.hasAttribute('data-reordered')) {\n" +
                "                        const firstCell = table.querySelector('tr td');\n" +
                "                        if (firstCell && firstCell.textContent.includes('.feature')) {\n" +
                "                            console.log('Periodic check found unordered tags table');\n" +
                "                            reorderTable(table);\n" +
                "                            table.setAttribute('data-reordered', 'true');\n" +
                "                            foundUnorderedTagsTable = true;\n" +
                "                        }\n" +
                "                    }\n" +
                "                }\n" +
                "            }, 3000);\n" +
                "        }, 100);\n" +
                "    }\n" +
                "    \n" +
                "    if (document.readyState === 'loading') {\n" +
                "        document.addEventListener('DOMContentLoaded', enhance);\n" +
                "    } else {\n" +
                "        enhance();\n" +
                "    }\n" +
                "})();";
            
            // Replace the placeholder with the dynamic order
            final String finalCustomJS = customJS.replace("__DYNAMIC_ORDER__", orderArray);
            
            // Process HTML files
            try (Stream<Path> files = Files.walk(reportsDir)) {
                long enhanced = files.filter(path -> path.toString().endsWith(".html"))
                     .peek(htmlFile -> enhanceHtmlFile(htmlFile, finalCustomJS))
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
            content = content.replaceAll("<script[^>]*>\\s*\\(function\\(\\)[\\s\\S]*?\\}\\)\\(\\);?\\s*</script>", "");
            
            // Also clean up any existing markers
            content = content.replaceAll("<div[^>]*id=\"scenarios-added\"[^>]*></div>", "");
            
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