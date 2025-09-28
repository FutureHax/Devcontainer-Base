#!/usr/bin/env node

// Build .devcontainer from common + specific

const fs = require('fs');
const path = require('path');

console.log('🔧 Building .devcontainer from common + specific...');

// Clean and create .devcontainer
if (fs.existsSync('.devcontainer')) {
    fs.rmSync('.devcontainer', { recursive: true });
}
fs.mkdirSync('.devcontainer');

// Read base configuration
let baseConfig = {
    "name": "${localWorkspaceFolderBasename} Dev Container",
    "build": {
        "dockerfile": "../.devcontainer-common/.devcontainer/Dockerfile",
        "context": "../.devcontainer-common/.devcontainer"
    },
    "postCreateCommand": "cd .devcontainer-common && sh .devcontainer/postCreateCommand.sh",
    "workspaceFolder": "/workspaces/${localWorkspaceFolderBasename}"
};

// Load actual base config to inherit features and extensions
const baseConfigPath = '.devcontainer-common/.devcontainer/devcontainer.json';
if (fs.existsSync(baseConfigPath)) {
    const baseContent = fs.readFileSync(baseConfigPath, 'utf8');
    const cleanBaseJson = baseContent
        .replace(/\/\/.*$/gm, '')
        .replace(/\/\*[\s\S]*?\*\//g, '')
        .replace(/,\s*([\]}])/g, '$1');
    
    try {
        const loadedBaseConfig = JSON.parse(cleanBaseJson);
        // Take features, customizations, and containerEnv from base
        baseConfig.features = loadedBaseConfig.features || {};
        baseConfig.customizations = loadedBaseConfig.customizations || {};
        baseConfig.containerEnv = loadedBaseConfig.containerEnv || {};
        baseConfig.mounts = loadedBaseConfig.mounts || [];
    } catch (e) {
        console.error('⚠️  Error parsing base config:', e.message);
    }
}

// Read project-specific config if exists
let finalConfig = { ...baseConfig };
if (fs.existsSync('.devcontainer-specific/devcontainer.json')) {
    const specificContent = fs.readFileSync('.devcontainer-specific/devcontainer.json', 'utf8');
    // Strip comments for parsing
    const cleanJson = specificContent
        .replace(/\/\/.*$/gm, '')
        .replace(/\/\*[\s\S]*?\*\//g, '')
        .replace(/,\s*([\]}])/g, '$1');
    
    try {
        const specificConfig = JSON.parse(cleanJson);
        
        // Deep merge function for nested objects
        const deepMerge = (target, source) => {
            const output = { ...target };
            Object.keys(source).forEach(key => {
                if (source[key] && typeof source[key] === 'object' && !Array.isArray(source[key])) {
                    output[key] = deepMerge(target[key] || {}, source[key]);
                } else if (Array.isArray(source[key]) && Array.isArray(target[key])) {
                    output[key] = [...new Set([...target[key], ...source[key]])];
                } else {
                    output[key] = source[key];
                }
            });
            return output;
        };
        
        // Merge configurations
        Object.keys(specificConfig).forEach(key => {
            if (key === 'features' || key === 'containerEnv' || key === 'customizations') {
                // Deep merge these objects
                finalConfig[key] = deepMerge(baseConfig[key] || {}, specificConfig[key] || {});
            } else {
                // Direct override for other keys
                finalConfig[key] = specificConfig[key];
            }
        });
    } catch (e) {
        console.error('⚠️  Error parsing project-specific config:', e.message);
    }
}

// Write the final configuration
fs.writeFileSync('.devcontainer/devcontainer.json', JSON.stringify(finalConfig, null, 2));

console.log('✅ Generated .devcontainer/devcontainer.json');
console.log('\n📁 Structure:');
console.log('   .devcontainer-common/    # Base (from submodule)');
console.log('   .devcontainer-specific/  # Your project config'); 
console.log('   .devcontainer/          # Generated (add to .gitignore)');
