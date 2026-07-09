# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended .NET version, for example:
```xml
<TargetFramework>net8.0</TargetFramework>
```
Ensure no projects are still referencing `net48` or other legacy .NET Framework monikers unless that is intentional.

### 2. Restore and Build Locally
Run the following commands from the solution root to confirm a clean restore and build:
```bash
dotnet restore
dotnet build --configuration Release
```
Review the output for any warnings that may indicate deprecated APIs or compatibility concerns, even if they are not hard errors.

### 3. Run Existing Tests
If the solution contains test projects, execute them to verify runtime behavior has not changed:
```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```
Review any failing tests carefully, as they may indicate behavioral differences between .NET Framework and the new .NET runtime.

### 4. Review Removed or Changed APIs
Check for usage of APIs that were present in .NET Framework but have changed behavior in modern .NET. Common areas to review include:
- `System.Web` dependencies (not available in modern .NET)
- `AppDomain` usage
- Reflection-based code
- Binary serialization (`BinaryFormatter` is disabled by default in .NET 5+)
- `ConfigurationManager` (requires the `System.Configuration.ConfigurationManager` NuGet package)

### 5. Verify NuGet Package Compatibility
Open the `.csproj` files and review all `<PackageReference>` entries. Confirm that each package version supports your target framework. You can cross-check on [nuget.org](https://www.nuget.org) or by running:
```bash
dotnet list package --outdated
```

### 6. Check Runtime Configuration
Review `appsettings.json`, `app.config`, or `web.config` files to ensure configuration values are being read correctly under the new hosting and configuration model.

### 7. Smoke Test Core Functionality
Manually exercise the primary entry points of the application to confirm expected behavior. Focus on:
- Application startup and initialization
- Core business logic paths
- Any external integrations (databases, HTTP clients, file I/O)

## Deployment Steps

### 1. Publish the Application
Use the `dotnet publish` command to produce deployment artifacts:
```bash
dotnet publish --configuration Release --output ./publish
```
For a self-contained deployment (no .NET runtime required on the target machine):
```bash
dotnet publish --configuration Release --self-contained true --runtime win-x64 --output ./publish
```
Replace `win-x64` with the appropriate runtime identifier for your target environment (e.g., `linux-x64`, `osx-x64`).

### 2. Verify the Published Output
Inspect the `./publish` directory to confirm all expected assemblies, configuration files, and static assets are present.

### 3. Test the Published Artifact
Run the published output directly on the target machine or an environment that mirrors it, before deploying to production:
```bash
./publish/AdoCore
```
Or on Windows:
```bash
publish\AdoCore.exe
```

### 4. Update Any Deployment Scripts
If existing deployment scripts reference `msbuild`, `.exe` outputs from .NET Framework, or other legacy tooling, update them to use `dotnet publish` and the new output paths accordingly.