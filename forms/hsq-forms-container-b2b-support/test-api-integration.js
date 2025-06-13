#!/usr/bin/env node

/**
 * Test script for B2B Support Form API integration
 * Tests customer validation and form submission with Husqvarna Group API
 */

const API_BASE_URL = process.env.VITE_API_URL || 'http://localhost:8000/api';
const HUSQVARNA_API_BASE_URL = process.env.VITE_HUSQVARNA_API_BASE_URL || 'https://api-qa.integration.husqvarnagroup.com/hqw170/v1';
const HUSQVARNA_API_KEY = process.env.VITE_HUSQVARNA_API_KEY || '3d9c4d8a3c5c47f1a2a0ec096496a786';

console.log('🧪 B2B Support Form Integration Test');
console.log('=====================================');
console.log(`API Base URL: ${API_BASE_URL}`);
console.log(`Husqvarna API Base URL: ${HUSQVARNA_API_BASE_URL}`);
console.log('');

/**
 * Test 1: Customer Number Validation
 */
async function testCustomerValidation() {
  console.log('📋 Test 1: Customer Number Validation');
  console.log('---------------------------------------');
  
  const testCustomerNumbers = [
    '1411768',      // Real customer number from colleague
    'VALID123',     // Should work with local validation
    'TEST456',      // Should work with local validation
    'ABC',          // Should work (minimum length)
    'AB',           // Should fail (too short)
    '123456789012345678901', // Should fail (too long)
    'invalid@#$'    // Should fail (invalid characters)
  ];
  
  for (const customerNumber of testCustomerNumbers) {
    console.log(`Testing customer number: ${customerNumber}`);
    
    try {
      // Test Husqvarna Group API validation
      const husqvarnaResponse = await fetch(`${HUSQVARNA_API_BASE_URL}/accounts?customerNumber=${customerNumber}&customerCode=DOJ`, {
        method: 'GET',
        headers: {
          'Ocp-Apim-Subscription-Key': HUSQVARNA_API_KEY,
          'Content-Type': 'application/json',
        },
      });
      
      if (husqvarnaResponse.ok) {
        const result = await husqvarnaResponse.json();
        console.log(`  ✅ Husqvarna API: Valid (Account ID: ${result.accountId || 'N/A'})`);
      } else {
        console.log(`  ❌ Husqvarna API: Invalid (Status: ${husqvarnaResponse.status})`);
      }
    } catch (error) {
      console.log(`  ⚠️  Husqvarna API: Connection failed - ${error.message}`);
      
      // Test fallback local validation
      const isValidFormat = /^[A-Z0-9]{3,20}$/.test(customerNumber.toUpperCase());
      console.log(`  ${isValidFormat ? '✅' : '❌'} Local validation: ${isValidFormat ? 'Valid format' : 'Invalid format'}`);
    }
    
    console.log('');
  }
}

/**
 * Test 2: Form Submission to HSQ Forms API
 */
async function testFormSubmission() {
  console.log('📋 Test 2: Form Submission to HSQ Forms API');
  console.log('----------------------------------------------');
  
  const templateId = '958915ec-fed1-4e7e-badd-4598502fe6a1';
  
  const testFormData = {
    companyName: 'Test Company AB',
    contactPerson: 'Test Person',
    customerNumber: '1411768', // Real customer number from colleague
    email: 'test@testcompany.com',
    phone: '+46701234567',
    subject: 'Test Subject - API Integration Test',
    supportType: 'technical',
    pncNumber: '967623401',
    serialNumber: 'SN123456789',
    problemDescription: 'This is a test submission to verify API integration functionality. Please ignore this test case.',
    urgency: 'low',
    language: 'sv'
  };
  
  try {
    console.log('Sending test form submission...');
    
    const response = await fetch(`${API_BASE_URL}/templates/${templateId}/submit`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        data: testFormData,
        metadata: {
          source: 'api-integration-test',
          customerValidated: true,
          accountId: '8cc804f3-0de1-e911-a812-000d3a252d60', // Real Account ID
          testMode: true
        }
      }),
    });
    
    const result = await response.json();
    
    if (response.ok && result.success !== false) {
      console.log('✅ Form submission successful!');
      console.log(`   Submission ID: ${result.submission?.id || result.id || 'N/A'}`);
      console.log(`   Status: ${result.status || 'submitted'}`);
      return result.submission?.id || result.id;
    } else {
      console.log('❌ Form submission failed!');
      console.log(`   Error: ${result.detail || result.error || 'Unknown error'}`);
      return null;
    }
  } catch (error) {
    console.log('❌ Form submission failed with network error!');
    console.log(`   Error: ${error.message}`);
    return null;
  }
}

/**
 * Test 3: Husqvarna Group Cases API Integration
 */
async function testHusqvarnaCasesAPI() {
  console.log('📋 Test 3: Husqvarna Group Cases API Integration');
  console.log('-------------------------------------------------');
  
  const testCaseData = {
    accountId: '8cc804f3-0de1-e911-a812-000d3a252d60', // Real Account ID from Husqvarna API
    customerNumber: '1411768', // Real customer number from colleague
    customerCode: 'DOJ',
    caseOriginCode: '115000008',
    description: 'API Integration Test Case - Please ignore this test submission'
  };
  
  try {
    console.log('Sending test case to Husqvarna Group Cases API...');
    
    const response = await fetch(`${HUSQVARNA_API_BASE_URL}/cases`, {
      method: 'POST',
      headers: {
        'Ocp-Apim-Subscription-Key': HUSQVARNA_API_KEY,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(testCaseData),
    });
    
    if (response.ok) {
      const result = await response.json();
      console.log('✅ Husqvarna Cases API integration successful!');
      console.log(`   Case ID: ${result.caseId || result.id || 'N/A'}`);
      console.log(`   Status: ${result.status || 'created'}`);
    } else {
      const errorText = await response.text();
      console.log('❌ Husqvarna Cases API integration failed!');
      console.log(`   Status: ${response.status}`);
      console.log(`   Error: ${errorText}`);
    }
  } catch (error) {
    console.log('❌ Husqvarna Cases API integration failed with network error!');
    console.log(`   Error: ${error.message}`);
  }
}

/**
 * Test 4: ESB Fallback Integration
 */
async function testESBFallback() {
  console.log('📋 Test 4: ESB Fallback Integration');
  console.log('------------------------------------');
  
  const testESBData = {
    name: 'Test Person',
    email: 'test@testcompany.com',
    company: 'Test Company AB',
    phone: '+46701234567',
    customerNumber: 'TEST123',
    subject: 'Test Subject - ESB Fallback Test',
    message: 'This is a test submission to verify ESB fallback functionality.',
    supportType: 'technical',
    pncNumber: '967623401',
    serialNumber: 'SN123456789',
    urgency: 'low',
    localSubmissionId: 'test-submission-id',
    accountId: 'TEST123',
    customerCode: 'DOJ',
    source: 'api-integration-test-esb-fallback'
  };
  
  try {
    console.log('Sending test to ESB fallback system...');
    
    const response = await fetch('https://api.hsqforms.se/esb/b2b-support', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(testESBData),
    });
    
    if (response.ok) {
      const result = await response.json();
      console.log('✅ ESB fallback integration successful!');
      console.log(`   ESB Response: ${JSON.stringify(result, null, 2)}`);
    } else {
      console.log('❌ ESB fallback integration failed (expected for test environment)');
      console.log(`   Status: ${response.status}`);
    }
  } catch (error) {
    console.log('⚠️  ESB fallback integration failed with network error (expected for test environment)');
    console.log(`   Error: ${error.message}`);
  }
}

/**
 * Run all tests
 */
async function runAllTests() {
  try {
    await testCustomerValidation();
    console.log('');
    
    const submissionId = await testFormSubmission();
    console.log('');
    
    await testHusqvarnaCasesAPI();
    console.log('');
    
    await testESBFallback();
    console.log('');
    
    console.log('🎉 Integration testing completed!');
    console.log('==================================');
    console.log('Summary:');
    console.log('- Customer validation: Tests completed');
    console.log('- HSQ Forms API: Tests completed');
    console.log('- Husqvarna Group Cases API: Tests completed');
    console.log('- ESB Fallback: Tests completed');
    console.log('');
    console.log('Note: Some failures are expected in test environment.');
    console.log('The important thing is that the fallback mechanisms work correctly.');
    
  } catch (error) {
    console.error('❌ Test execution failed:', error);
  }
}

// Run tests if this script is executed directly
import { fileURLToPath } from 'url';
import { dirname } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// Check if this script is being run directly
if (import.meta.url === `file://${process.argv[1]}`) {
  runAllTests();
}

export {
  testCustomerValidation,
  testFormSubmission,
  testHusqvarnaCasesAPI,
  testESBFallback,
  runAllTests
};
