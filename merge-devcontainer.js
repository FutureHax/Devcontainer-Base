#!/usr/bin/env node

// Helper script to merge existing devcontainer.json with base configuration
// This preserves project customizations while using the base Dockerfile

const fs = require('fs');
const path = require('path');

const projectConfigPath = '.devcontainer/devcontainer.json';
const baseConfigPath = '.devcontainer-common/.devcontainer/devcontainer.json';

// Read existing project config
let projectConfig = {};
if (fs.existsSync(projectConfigPath)) {
    projectConfig = JSON.parse(fs.readFileSync(projectConfigPath, 'utf8'));
}

// Read base config for reference
let baseConfig = {};
if (fs.existsSync(baseConfigPath)) {
    baseConfig = JSON.parse(fs.readFileSync(baseConfigPath, 'utf8'));
}

// Merge configuration
const mergedConfig = {
    ...projectConfig,
    
    // Always use base Dockerfile
    "build": {
        "dockerfile": "../.devcontainer-common/.devcontainer/Dockerfile",
        "context": "../.devcontainer-common/.devcontainer",
        // Preserve any build args from project
        ...(projectConfig.build?.args && { args: projectConfig.build.args })
    },
    
    // Merge features (base + project)
    "features": {
        ...baseConfig.features,
        ...projectConfig.features
    },
    
    // Merge customizations
    "customizations": {
        "vscode": {
            "settings": {
                ...baseConfig.customizations?.vscode?.settings,
                ...projectConfig.customizations?.vscode?.settings
            },
            "extensions": [
                ...(baseConfig.customizations?.vscode?.extensions || []),
                ...(projectConfig.customizations?.vscode?.extensions || [])
            ].filter((v, i, a) => a.indexOf(v) === i) // Remove duplicates
        }
    },
    
    // Merge environment variables
    "containerEnv": {
        ...baseConfig.containerEnv,
        ...projectConfig.containerEnv
    },
    
    // Combine postCreateCommands
    "postCreateCommand": combineCommands(
        "cd .devcontainer-common && sh .devcontainer/postCreateCommand.sh",
        projectConfig.postCreateCommand
    ),
    
    // Ensure workspace folder is set correctly
    "workspaceFolder": "/workspaces/${localWorkspaceFolderBasename}"
};

// Helper to combine commands
function combineCommands(baseCmd, projectCmd) {
    if (!projectCmd) return baseCmd;
    
    // Extract the base command path for comparison
    const baseCmdCore = 'cd .devcontainer-common && sh .devcontainer/postCreateCommand.sh';
    
    if (typeof projectCmd === 'string') {
        // If project command already includes the base setup, don't duplicate
        if (projectCmd.includes(baseCmdCore)) {
            return projectCmd;
        }
        // Otherwise prepend base command
        return `${baseCmd} && ${projectCmd}`;
    }
    
    // If project command is array, prepend base command
    if (Array.isArray(projectCmd)) {
        // Check if first command is already the base
        if (projectCmd[0] && projectCmd[0].includes(baseCmdCore)) {
            return projectCmd;
        }
        return [baseCmd, ...projectCmd];
    }
    
    return baseCmd;
}

// Write merged config
fs.writeFileSync(projectConfigPath, JSON.stringify(mergedConfig, null, 2));
console.log('✅ Successfully merged devcontainer configuration with base');
