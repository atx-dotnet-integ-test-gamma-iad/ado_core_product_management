# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48` or other legacy .NET Framework monikers unless that is intentional.

### 2. Restore Dependencies
Run the following command from the solution root to confirm all NuGet packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or version conflicts.

### 3. Build the Solution
Perform a clean build to confirm there are no issues beyond what the initial error report captured:

```bash
dotnet build --configuration Release
```

Address any warnings that surface, particularly those related to nullable reference types or obsolete APIs, as these can indicate subtle compatibility issues.

### 4. Run the Test Suite
If the solution contains test projects, execute them to verify runtime behavior has not changed:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully, as failures may indicate behavioral differences between .NET Framework and cross-platform .NET (e.g., differences in globalization, file path handling, or reflection behavior).

### 5. Check for Platform-Specific Code
Search the codebase for APIs that were available in .NET Framework but behave differently or are unavailable in cross-platform .NET. Common areas to inspect include:

- `System.Windows.Forms` or `System.Web` references (these are not cross-platform)
- Registry access (`Microsoft.Win32.Registry`)
- `AppDomain` usage
- `BinaryFormatter` (deprecated and disabled by default in modern .NET)
- P/Invoke calls targeting Windows-specific native libraries

### 6. Review Runtime Configuration
Check for an `app.config` or `web.config` file. These are not used in the same way in modern .NET. Any relevant settings should be migrated to `appsettings.json` or `runtimeconfig.json` as appropriate.

### 7. Validate Output Artifacts
After a successful Release build, inspect the output directory (typically `bin/Release/net8.0/`) to confirm the expected assemblies, dependencies, and configuration files are present.

## Deployment

### 1. Publish the Application
Use the `dotnet publish` command to produce deployment artifacts:

```bash
dotnet publish --configuration Release --output ./publish
```

For a self-contained deployment that does not require .NET to be installed on the target machine:

```bash
dotnet publish --configuration Release --self-contained true --runtime <runtime-identifier> --output ./publish
```

Replace `<runtime-identifier>` with the appropriate value for your target platform, for example `win-x64`, `linux-x64`, or `osx-x64`.

### 2. Verify the Published Output
Run the published application from the output directory to confirm it starts and behaves correctly in an environment that mirrors production as closely as possible.

```bash
cd ./publish
dotnet AdoCore.dll
```

Or, if published as self-contained:

```bash
./AdoCore
```

### 3. Review Dependency Versions Before Deployment
Run the following to list all resolved package versions and confirm no packages carry known vulnerabilities:

```bash
dotnet list package --vulnerable
```

Address any flagged packages by updating to a patched version in the relevant `.csproj` files.