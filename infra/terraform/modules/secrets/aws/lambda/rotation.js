/**
 * AWS Secrets Manager RDS PostgreSQL Password Rotation Lambda
 * 
 * This Lambda function rotates RDS PostgreSQL credentials stored in AWS Secrets Manager.
 * It follows the AWS recommended rotation strategy for RDS:
 * 
 * 1. createSecret: Generate new password and create AWSPENDING version
 * 2. setSecret: Update the database user with the new password
 * 3. testSecret: Test the new credentials
 * 4. finishSecret: Mark AWSPENDING as AWSCURRENT
 * 
 * Reference: https://docs.aws.amazon.com/secretsmanager/latest/userguide/rotating-secrets-rds.html
 */

const { SecretsManagerClient, GetSecretValueCommand, PutSecretValueCommand, UpdateSecretVersionStageCommand, GetRandomPasswordCommand } = require('@aws-sdk/client-secrets-manager');
const { Client } = require('pg');

const secretsManager = new SecretsManagerClient({});

/**
 * Main Lambda handler for secret rotation
 */
exports.handler = async (event) => {
    const { SecretId: secretId, Token: token, Step: step } = event;
    
    console.log(`Starting rotation step: ${step} for secret: ${secretId}`);
    
    try {
        switch (step) {
            case 'createSecret':
                await createSecret(secretId, token);
                break;
            case 'setSecret':
                await setSecret(secretId, token);
                break;
            case 'testSecret':
                await testSecret(secretId, token);
                break;
            case 'finishSecret':
                await finishSecret(secretId, token);
                break;
            default:
                throw new Error(`Invalid rotation step: ${step}`);
        }
        
        console.log(`Successfully completed rotation step: ${step}`);
    } catch (error) {
        console.error(`Error during rotation step ${step}:`, error);
        throw error;
    }
};

/**
 * Step 1: Create a new secret version with a generated password
 */
async function createSecret(secretId, token) {
    // Get the current secret
    const currentSecret = await getSecretValue(secretId, 'AWSCURRENT');
    
    // Check if the pending version already exists
    try {
        await getSecretValue(secretId, 'AWSPENDING', token);
        console.log('createSecret: Secret version already exists, skipping creation');
        return;
    } catch (error) {
        // Expected - secret doesn't exist yet
    }
    
    // Generate a new password
    const passwordCommand = new GetRandomPasswordCommand({
        PasswordLength: 32,
        ExcludeCharacters: '"@/\\\'',
        RequireEachIncludedType: true
    });
    
    const passwordResponse = await secretsManager.send(passwordCommand);
    const newPassword = passwordResponse.RandomPassword;
    
    // Create new secret version with the new password
    const newSecret = {
        ...currentSecret,
        password: newPassword
    };
    
    const putCommand = new PutSecretValueCommand({
        SecretId: secretId,
        ClientRequestToken: token,
        SecretString: JSON.stringify(newSecret),
        VersionStages: ['AWSPENDING']
    });
    
    await secretsManager.send(putCommand);
    console.log('createSecret: Successfully created new secret version');
}

/**
 * Step 2: Set the password in the database
 */
async function setSecret(secretId, token) {
    const currentSecret = await getSecretValue(secretId, 'AWSCURRENT');
    const pendingSecret = await getSecretValue(secretId, 'AWSPENDING', token);
    
    // Connect to the database using current credentials
    const client = new Client({
        host: currentSecret.host,
        port: currentSecret.port,
        database: currentSecret.dbname,
        user: currentSecret.username,
        password: currentSecret.password,
        ssl: {
            rejectUnauthorized: false
        }
    });
    
    try {
        await client.connect();
        console.log('setSecret: Connected to database');
        
        // Update the user's password
        const query = `ALTER USER ${currentSecret.username} WITH PASSWORD '${pendingSecret.password}'`;
        await client.query(query);
        
        console.log('setSecret: Successfully updated password in database');
    } finally {
        await client.end();
    }
}

/**
 * Step 3: Test the new credentials
 */
async function testSecret(secretId, token) {
    const pendingSecret = await getSecretValue(secretId, 'AWSPENDING', token);
    
    // Test connection with new credentials
    const client = new Client({
        host: pendingSecret.host,
        port: pendingSecret.port,
        database: pendingSecret.dbname,
        user: pendingSecret.username,
        password: pendingSecret.password,
        ssl: {
            rejectUnauthorized: false
        }
    });
    
    try {
        await client.connect();
        console.log('testSecret: Successfully connected with new credentials');
        
        // Test a simple query
        const result = await client.query('SELECT 1 as test');
        if (result.rows[0].test !== 1) {
            throw new Error('Test query failed');
        }
        
        console.log('testSecret: Test query successful');
    } finally {
        await client.end();
    }
}

/**
 * Step 4: Finalize the rotation by updating version stages
 */
async function finishSecret(secretId, token) {
    // Get current version ID
    const describeCommand = new GetSecretValueCommand({
        SecretId: secretId,
        VersionStage: 'AWSCURRENT'
    });
    
    const currentVersion = await secretsManager.send(describeCommand);
    const currentVersionId = currentVersion.VersionId;
    
    // Move AWSCURRENT stage to the new version
    const updateCommand = new UpdateSecretVersionStageCommand({
        SecretId: secretId,
        VersionStage: 'AWSCURRENT',
        MoveToVersionId: token,
        RemoveFromVersionId: currentVersionId
    });
    
    await secretsManager.send(updateCommand);
    console.log('finishSecret: Successfully updated version stages');
}

/**
 * Helper function to retrieve a secret value
 */
async function getSecretValue(secretId, stage, token = null) {
    const params = {
        SecretId: secretId,
        VersionStage: stage
    };
    
    if (token) {
        params.VersionId = token;
    }
    
    const command = new GetSecretValueCommand(params);
    const response = await secretsManager.send(command);
    
    return JSON.parse(response.SecretString);
}
