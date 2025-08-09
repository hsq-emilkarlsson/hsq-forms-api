/**
 * HSQ Forms API Debugging Tool
 * 
 * Detta är ett JavaScript-verktyg för att diagnostisera kommunikationsproblem 
 * mellan formulär och API. Lägg till detta i ett formulär för att få detaljerad 
 * loggning av API-anrop.
 * 
 * Uppdaterad: 2025-08-09
 */

// Självexekverande funktion för att undvika global scope
(function() {
    // Skapa debug-interface
    const createDebugInterface = () => {
        const debugPanel = document.createElement('div');
        debugPanel.id = 'hsq-debug-panel';
        debugPanel.style.cssText = `
            position: fixed;
            bottom: 0;
            right: 0;
            width: 50%;
            height: 300px;
            background: rgba(0, 0, 0, 0.8);
            color: #33ff33;
            font-family: monospace;
            font-size: 12px;
            padding: 10px;
            overflow: auto;
            z-index: 10000;
            border-top-left-radius: 5px;
            display: none;
        `;

        const debugHeader = document.createElement('div');
        debugHeader.innerHTML = '<h3>HSQ Forms API Debug Console</h3>';
        debugHeader.style.marginBottom = '10px';
        debugHeader.style.borderBottom = '1px solid #33ff33';
        debugHeader.style.paddingBottom = '5px';
        
        const debugContent = document.createElement('div');
        debugContent.id = 'hsq-debug-content';
        debugContent.style.height = 'calc(100% - 80px)';
        debugContent.style.overflowY = 'auto';
        
        const debugControls = document.createElement('div');
        debugControls.style.marginTop = '10px';
        debugControls.style.borderTop = '1px solid #33ff33';
        debugControls.style.paddingTop = '5px';
        
        const clearBtn = document.createElement('button');
        clearBtn.textContent = 'Rensa';
        clearBtn.onclick = () => {
            document.getElementById('hsq-debug-content').innerHTML = '';
        };
        
        const testBtn = document.createElement('button');
        testBtn.textContent = 'Testa API';
        testBtn.onclick = testApiConnection;
        
        const closeBtn = document.createElement('button');
        closeBtn.textContent = 'Stäng';
        closeBtn.onclick = () => {
            document.getElementById('hsq-debug-panel').style.display = 'none';
        };
        
        debugControls.appendChild(clearBtn);
        debugControls.appendChild(document.createTextNode(' '));
        debugControls.appendChild(testBtn);
        debugControls.appendChild(document.createTextNode(' '));
        debugControls.appendChild(closeBtn);
        
        debugPanel.appendChild(debugHeader);
        debugPanel.appendChild(debugContent);
        debugPanel.appendChild(debugControls);
        
        document.body.appendChild(debugPanel);
        
        // Lägg till en knapp för att visa debug-panelen
        const debugToggle = document.createElement('div');
        debugToggle.id = 'hsq-debug-toggle';
        debugToggle.textContent = '🔍';
        debugToggle.title = 'Visa/Dölj API Debug';
        debugToggle.style.cssText = `
            position: fixed;
            bottom: 10px;
            right: 10px;
            width: 30px;
            height: 30px;
            background: rgba(0, 0, 0, 0.7);
            color: #33ff33;
            font-size: 18px;
            text-align: center;
            line-height: 30px;
            border-radius: 50%;
            cursor: pointer;
            z-index: 10001;
            user-select: none;
        `;
        
        debugToggle.onclick = () => {
            const panel = document.getElementById('hsq-debug-panel');
            panel.style.display = panel.style.display === 'none' ? 'block' : 'none';
        };
        
        document.body.appendChild(debugToggle);
    };
    
    // Funktion för att logga meddelanden
    const log = (message, type = 'info') => {
        const debugContent = document.getElementById('hsq-debug-content');
        if (!debugContent) return;
        
        const entry = document.createElement('div');
        const timestamp = new Date().toLocaleTimeString();
        let color = '#33ff33'; // default grön för info
        
        switch (type) {
            case 'error':
                color = '#ff3333';
                break;
            case 'warning':
                color = '#ffff33';
                break;
            case 'success':
                color = '#33ff33';
                break;
            case 'http':
                color = '#33ccff';
                break;
        }
        
        entry.style.color = color;
        entry.innerHTML = `[${timestamp}] ${message}`;
        debugContent.appendChild(entry);
        debugContent.scrollTop = debugContent.scrollHeight; // Auto-scroll
    };
    
    // Funktion för att testa API-anslutningen
    const testApiConnection = async () => {
        const apiUrl = (window.VITE_API_URL || localStorage.getItem('apiUrl') || '').trim();
        const apiKey = (window.VITE_API_KEY || localStorage.getItem('apiKey') || '').trim();
        const apiKeyHeader = (window.VITE_API_KEY_HEADER_NAME || 'X-API-Key').trim();
        
        if (!apiUrl) {
            log('API URL är inte konfigurerad', 'error');
            return;
        }
        
        log(`Testar anslutning till API: ${apiUrl}`, 'info');
        log(`API nyckel: ${apiKey ? '********' : 'Inte konfigurerad'}`, 'info');
        log(`API nyckelheader: ${apiKeyHeader}`, 'info');
        
        // Testa /api/health
        try {
            log('Testar health endpoint...', 'info');
            const healthStart = performance.now();
            const healthResponse = await fetch(`${apiUrl}/api/health`, {
                method: 'GET',
                headers: apiKey ? { [apiKeyHeader]: apiKey } : {}
            });
            const healthDuration = (performance.now() - healthStart).toFixed(2);
            
            if (healthResponse.ok) {
                const healthData = await healthResponse.json();
                log(`✓ Health check OK (${healthDuration}ms): ${JSON.stringify(healthData)}`, 'success');
            } else {
                log(`✗ Health check misslyckades: ${healthResponse.status} ${healthResponse.statusText} (${healthDuration}ms)`, 'error');
            }
        } catch (error) {
            log(`✗ Health check error: ${error.message}`, 'error');
        }
        
        // Testa /api/v1/forms
        try {
            log('Hämtar tillgängliga formulär...', 'info');
            const formsStart = performance.now();
            const formsResponse = await fetch(`${apiUrl}/api/v1/forms`, {
                method: 'GET',
                headers: apiKey ? { [apiKeyHeader]: apiKey } : {}
            });
            const formsDuration = (performance.now() - formsStart).toFixed(2);
            
            if (formsResponse.ok) {
                const formsData = await formsResponse.json();
                log(`✓ Formulärlistning OK (${formsDuration}ms): ${formsData.length} formulär hittades`, 'success');
                formsData.forEach(form => {
                    log(`  - ${form.id}: ${form.name}`, 'success');
                });
            } else {
                log(`✗ Formulärlistning misslyckades: ${formsResponse.status} ${formsResponse.statusText} (${formsDuration}ms)`, 'error');
            }
        } catch (error) {
            log(`✗ Formulärlistning error: ${error.message}`, 'error');
        }
        
        // Visa CORS headers
        log('CORS Headers från server:', 'info');
        try {
            const corsResponse = await fetch(`${apiUrl}/api/v1/forms`, {
                method: 'OPTIONS',
                headers: {
                    'Origin': window.location.origin,
                    'Access-Control-Request-Method': 'POST',
                    'Access-Control-Request-Headers': `Content-Type, ${apiKeyHeader}`
                }
            });
            
            const corsHeaders = [
                'Access-Control-Allow-Origin',
                'Access-Control-Allow-Methods',
                'Access-Control-Allow-Headers',
                'Access-Control-Allow-Credentials',
                'Access-Control-Max-Age'
            ];
            
            corsHeaders.forEach(header => {
                const value = corsResponse.headers.get(header);
                if (value) {
                    log(`  ${header}: ${value}`, 'success');
                } else {
                    log(`  ${header}: Saknas`, 'warning');
                }
            });
        } catch (error) {
            log(`✗ CORS check error: ${error.message}`, 'error');
        }
        
        // Samla och visa miljövariabler
        log('Miljövariabler och konfiguration:', 'info');
        const config = {
            'API URL': apiUrl,
            'API Key Header': apiKeyHeader,
            'API Key': apiKey ? '********' : 'Inte konfigurerad',
            'Origin': window.location.origin,
            'Formulär URL': window.location.href,
            'User Agent': navigator.userAgent,
            'Webbläsare': `${navigator.userAgentData?.brands[0]?.brand || 'Unknown'} ${navigator.userAgentData?.brands[0]?.version || ''}`,
            'Plattform': navigator.platform
        };
        
        Object.entries(config).forEach(([key, value]) => {
            log(`  ${key}: ${value}`, 'info');
        });
    };
    
    // Funktion för att övervaka alla fetch-anrop
    const monitorFetch = () => {
        const originalFetch = window.fetch;
        
        window.fetch = async function(url, options = {}) {
            const isApiCall = url.toString().includes(window.VITE_API_URL || localStorage.getItem('apiUrl') || '');
            
            if (isApiCall) {
                const method = options.method || 'GET';
                log(`🌐 ${method} ${url}`, 'http');
                
                if (options.headers) {
                    log(`Headers: ${JSON.stringify(options.headers)}`, 'http');
                }
                
                if (options.body) {
                    try {
                        const body = typeof options.body === 'string' 
                            ? JSON.parse(options.body) 
                            : options.body;
                        log(`Request Body: ${JSON.stringify(body)}`, 'http');
                    } catch (e) {
                        log(`Request Body: [Kunde inte tolka]`, 'http');
                    }
                }
                
                const startTime = performance.now();
                try {
                    const response = await originalFetch.apply(this, arguments);
                    const duration = (performance.now() - startTime).toFixed(2);
                    
                    log(`Response: ${response.status} ${response.statusText} (${duration}ms)`, response.ok ? 'success' : 'error');
                    
                    // Klona responsen för att kunna läsa body
                    const clonedResponse = response.clone();
                    try {
                        const data = await clonedResponse.text();
                        try {
                            const jsonData = JSON.parse(data);
                            log(`Response Body: ${JSON.stringify(jsonData)}`, 'http');
                        } catch (e) {
                            if (data && data.length < 500) {
                                log(`Response Body: ${data}`, 'http');
                            } else {
                                log(`Response Body: [För stor för att visa - ${data.length} tecken]`, 'http');
                            }
                        }
                    } catch (e) {
                        log(`Response Body: [Kunde inte läsa]`, 'warning');
                    }
                    
                    return response;
                } catch (error) {
                    const duration = (performance.now() - startTime).toFixed(2);
                    log(`⚠ Fetch Error (${duration}ms): ${error.message}`, 'error');
                    throw error;
                }
            }
            
            return originalFetch.apply(this, arguments);
        };
    };
    
    // Monitorera XHR också för äldre implementationer
    const monitorXHR = () => {
        const originalOpen = XMLHttpRequest.prototype.open;
        const originalSend = XMLHttpRequest.prototype.send;
        
        XMLHttpRequest.prototype.open = function(method, url, ...rest) {
            this._hsqMethod = method;
            this._hsqUrl = url;
            this._hsqStartTime = performance.now();
            
            const isApiCall = url.toString().includes(window.VITE_API_URL || localStorage.getItem('apiUrl') || '');
            if (isApiCall) {
                log(`🌐 ${method} ${url} (XHR)`, 'http');
            }
            
            return originalOpen.apply(this, [method, url, ...rest]);
        };
        
        XMLHttpRequest.prototype.send = function(body) {
            const isApiCall = this._hsqUrl && this._hsqUrl.toString().includes(window.VITE_API_URL || localStorage.getItem('apiUrl') || '');
            
            if (isApiCall && body) {
                try {
                    const bodyContent = typeof body === 'string' ? JSON.parse(body) : body;
                    log(`Request Body (XHR): ${JSON.stringify(bodyContent)}`, 'http');
                } catch (e) {
                    log(`Request Body (XHR): [Kunde inte tolka]`, 'http');
                }
            }
            
            if (isApiCall) {
                this.addEventListener('load', function() {
                    const duration = (performance.now() - this._hsqStartTime).toFixed(2);
                    const status = this.status;
                    const statusText = this.statusText;
                    
                    log(`Response (XHR): ${status} ${statusText} (${duration}ms)`, status >= 200 && status < 300 ? 'success' : 'error');
                    
                    if (this.responseText) {
                        try {
                            const jsonData = JSON.parse(this.responseText);
                            log(`Response Body (XHR): ${JSON.stringify(jsonData)}`, 'http');
                        } catch (e) {
                            if (this.responseText && this.responseText.length < 500) {
                                log(`Response Body (XHR): ${this.responseText}`, 'http');
                            } else {
                                log(`Response Body (XHR): [För stor för att visa - ${this.responseText.length} tecken]`, 'http');
                            }
                        }
                    }
                });
                
                this.addEventListener('error', function() {
                    const duration = (performance.now() - this._hsqStartTime).toFixed(2);
                    log(`⚠ XHR Error (${duration}ms)`, 'error');
                });
            }
            
            return originalSend.apply(this, [body]);
        };
    };
    
    // Initiera verktyget när DOM är redo
    const init = () => {
        createDebugInterface();
        monitorFetch();
        monitorXHR();
        log('HSQ Forms API Debug Tool initierad', 'success');
        log('Tryck på 🔍-ikonen för att visa/dölja debug-panelen', 'info');
        log('Alla API-anrop kommer att övervakas och loggas här', 'info');
    };
    
    // Vänta på att DOM är redo
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', init);
    } else {
        init();
    }
})();
