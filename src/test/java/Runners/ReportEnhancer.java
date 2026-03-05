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
                "            // Reorder tags table if it exists\n" +
                "            const tagsTable = document.querySelector('.table-condensed tbody');\n" +
                "            if (tagsTable) {\n" +
                "                console.log('Reordering tags table');\n" +
                "                reorderTable(tagsTable);\n" +
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
                "            const order = ['Features/auth/checkUsername.feature','Features/auth/signup.feature','Features/auth/setpassword.feature','Features/auth/verifyEmail.feature','Features/auth/login.feature','Features/auth/forgotPassword.feature','Features/auth/verifyResetCode.feature','Features/auth/validateToken.feature','Features/auth/refreshToken.feature','Features/user-management/getUser.feature','Features/user-management/updateUser.feature','Features/eff-data/blitzLeagues/checkBlitzLeagueName.feature','Features/eff-data/exchangeTeams/checkExchangeTeamName.feature','Features/eff-data/exchangeLeagues/checkExchangeLeagueName.feature','helpers/setTimeframeToPreSeason.feature','Features/eff-data/leagues/getHomePagePublicExtremeLeagues.feature','Features/eff-data/leagues/getAvailableLeagues.feature','Features/eff-data/blitzLeagues/joinPublicBlitzLeague.feature','Features/eff-data/blitzTeams/createBlitzTeam.feature','Features/eff-data/blitzTeams/checkBlitzTeamName.feature','Features/eff-data/blitzTeams/getBlitzTeam.feature','Features/eff-data/blitzTeams/getBlitzTeams.feature','Features/eff-data/blitzTeams/getBlitzTeamsByLeague.feature','Features/eff-data/blitzLeagues/getBlitzLeague.feature','Features/eff-data/blitzLeagues/leavePublicBlitzLeague.feature','Features/eff-data/blitzLeagues/createBlitzLeague.feature','helpers/createSecondUser.feature','Features/eff-data/blitzLeagues/joinPrivateBlitzLeague.feature','Features/eff-data/blitzTeams/createBlitzTeamPrivateLeague.feature','Features/eff-data/blitzTeams/getBlitzTeamPrivateLeague.feature','Features/eff-data/blitzTeams/getBlitzTeamsPrivateLeague.feature','Features/eff-data/blitzTeams/getBlitzTeamsByPrivateLeague.feature','Features/eff-data/blitzLeagues/getPrivateBlitzLeague.feature','Features/eff-data/blitzLeagues/leavePrivateBlitzLeague.feature','Features/eff-data/exchangeLeagues/joinPublicExchangeLeague.feature','Features/eff-data/exchangeTeams/createExchangeTeam.feature','Features/user-management/deleteUserAccountByEmail.feature'];\n" +
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
                "    function setupTabObserver() {\n" +
                "        try {\n" +
                "            // Watch for tab clicks\n" +
                "            const tabs = document.querySelectorAll('a[href=\"#tags\"], a[href=\"#summary\"]');\n" +
                "            tabs.forEach(tab => {\n" +
                "                tab.addEventListener('click', () => {\n" +
                "                    setTimeout(() => {\n" +
                "                        console.log('Tab switched, reordering tables...');\n" +
                "                        reorderFeatures();\n" +
                "                    }, 200);\n" +
                "                });\n" +
                "            });\n" +
                "            \n" +
                "            // Also use MutationObserver to catch dynamic table changes\n" +
                "            const observer = new MutationObserver(() => {\n" +
                "                const tagsTable = document.querySelector('.table-condensed tbody');\n" +
                "                if (tagsTable && !tagsTable.hasAttribute('data-reordered')) {\n" +
                "                    setTimeout(() => {\n" +
                "                        console.log('New table detected, reordering...');\n" +
                "                        reorderTable(tagsTable);\n" +
                "                        tagsTable.setAttribute('data-reordered', 'true');\n" +
                "                    }, 100);\n" +
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
                "                const tagsTable = document.querySelector('.table-condensed tbody');\n" +
                "                if (tagsTable && !tagsTable.hasAttribute('data-reordered')) {\n" +
                "                    console.log('Late tags table detection, reordering...');\n" +
                "                    reorderTable(tagsTable);\n" +
                "                    tagsTable.setAttribute('data-reordered', 'true');\n" +
                "                }\n" +
                "            }, 1000);\n" +
                "        }, 100);\n" +
                "    }\n" +
                "    \n" +
                "    if (document.readyState === 'loading') {\n" +
                "        document.addEventListener('DOMContentLoaded', enhance);\n" +
                "    } else {\n" +
                "        enhance();\n" +
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