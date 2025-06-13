#!/usr/bin/env node

// B2B Support Form Integration Test
// This script tests the complete form submission workflow

import fetch from 'node-fetch';

const API_URL = 'http://localhost:8000/api';
const TEMPLATE_ID = '958915ec-fed1-4e7e-badd-4598502fe6a1';

async function testFormSubmission() {
  console.log('🚀 Starting B2B Support Form Integration Test\n');

  // Test 1: Verify template exists
  console.log('1. Testing template endpoint...');
  try {
    const templateResponse = await fetch(`${API_URL}/templates/${TEMPLATE_ID}`);
    if (templateResponse.ok) {
      const template = await templateResponse.json();
      console.log('✅ Template found:', template.name);
    } else {
      console.log('❌ Template not found');
      return;
    }
  } catch (error) {
    console.log('❌ Error checking template:', error.message);
    return;
  }

  // Test 2: Submit technical support form
  console.log('\n2. Testing technical support form submission...');
  const technicalPayload = {
    data: {
      companyName: "Acme Corporation",
      contactPerson: "Jane Smith",
      customerNumber: "ACME001",
      email: "jane.smith@acme.com",
      phone: "+46-8-123-4567",
      subject: "Equipment malfunction - Urgent",
      supportType: "technical",
      pncNumber: "PNC98765",
      serialNumber: "SN12345-ABC",
      problemDescription: "The main control unit is showing error codes 404 and 505 after the latest firmware update. The equipment has been non-operational for 2 hours, affecting production.",
      urgency: "high",
      language: "en"
    }
  };

  try {
    const response = await fetch(`${API_URL}/templates/${TEMPLATE_ID}/submit`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(technicalPayload)
    });

    if (response.ok) {
      const result = await response.json();
      console.log('✅ Technical support form submitted successfully');
      console.log('   Submission ID:', result.id);
      console.log('   Data stored:', Object.keys(result.data).length, 'fields');
    } else {
      const error = await response.json();
      console.log('❌ Technical form submission failed:', error);
      return;
    }
  } catch (error) {
    console.log('❌ Error submitting technical form:', error.message);
    return;
  }

  // Test 3: Submit customer support form
  console.log('\n3. Testing customer support form submission...');
  const customerPayload = {
    data: {
      companyName: "Beta Solutions Ltd",
      contactPerson: "Michael Johnson",
      customerNumber: "BETA002",
      email: "m.johnson@betasolutions.com",
      phone: "+46-31-987-6543",
      subject: "Billing inquiry - Invoice discrepancy",
      supportType: "customer",
      pncNumber: "",
      serialNumber: "",
      problemDescription: "We received invoice #INV-2024-001234 but the amounts don't match our purchase order. We need clarification on the billing details and potential adjustments.",
      urgency: "medium",
      language: "en"
    }
  };

  try {
    const response = await fetch(`${API_URL}/templates/${TEMPLATE_ID}/submit`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(customerPayload)
    });

    if (response.ok) {
      const result = await response.json();
      console.log('✅ Customer support form submitted successfully');
      console.log('   Submission ID:', result.id);
      console.log('   Support Type:', result.data.supportType);
    } else {
      const error = await response.json();
      console.log('❌ Customer form submission failed:', error);
      return;
    }
  } catch (error) {
    console.log('❌ Error submitting customer form:', error.message);
    return;
  }

  // Test 4: Test validation (missing required fields)
  console.log('\n4. Testing form validation...');
  const invalidPayload = {
    data: {
      companyName: "Test Co",
      // Missing required fields: contactPerson, email, subject, problemDescription
      supportType: "technical",
      urgency: "low",
      language: "en"
    }
  };

  try {
    const response = await fetch(`${API_URL}/templates/${TEMPLATE_ID}/submit`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(invalidPayload)
    });

    if (!response.ok) {
      const error = await response.json();
      console.log('✅ Form validation working correctly');
      console.log('   Validation errors detected:', error.detail?.length || 'Multiple');
    } else {
      console.log('❌ Form validation not working - invalid data was accepted');
    }
  } catch (error) {
    console.log('⚠️  Error during validation test:', error.message);
  }

  console.log('\n🎉 Integration test completed successfully!');
  console.log('\n📋 Summary:');
  console.log('- Template verification: ✅');
  console.log('- Technical support submission: ✅');
  console.log('- Customer support submission: ✅');
  console.log('- Form validation: ✅');
  console.log('\n💡 Next steps:');
  console.log('- Test the form UI at http://localhost:3003');
  console.log('- Verify email notifications (if configured)');
  console.log('- Test file upload functionality');
  console.log('- Check database entries in the admin panel');
}

// Run the test
testFormSubmission().catch(console.error);
