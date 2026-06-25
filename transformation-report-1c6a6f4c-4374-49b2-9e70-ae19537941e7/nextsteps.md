# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended .NET version, for example:
```xml
<TargetFramework>net8.0</TargetFramework>
```
Ensure no projects are still referencing `net48` or other legacy .NET Framework monikers unless that is intentional for multi-targeting.

### 2. Restore and Build Locally
Run the following commands from the solution root to confirm a clean restore and build:
```bash
dotnet restore
dotnet build --configuration Release
```
Review the output for any warnings that may indicate deprecated APIs or packages that could cause runtime issues.

### 3. Run Existing Tests
If the solution contains test projects, execute them to verify runtime behavior has not changed:
```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```
Review any failing tests carefully, as they may indicate behavioral differences between .NET Framework and cross-platform .NET.

### 4. Review NuGet Package Compatibility
Open each `.csproj` and review the `<PackageReference>` entries. For any package that was migrated from a `packages.config`, verify the package version is compatible with the target framework by checking [nuget.org](https://www.nuget.org). Pay particular attention to packages that wrap Windows-specific APIs.

### 5. Check for Platform-Specific API Usage
Use the .NET Upgrade Assistant or the `Microsoft.DotNet.PlatformAbstractions` analyzer to identify any calls to Windows-only APIs (e.g., `System.Drawing`, `Microsoft.Win32`, registry access). If the project is intended to run cross-platform, these will need to be replaced or conditionally compiled.

### 6. Validate Configuration Files
If the project previously used `App.config` or `Web.config`, confirm that settings have been migrated to `appsettings.json` or the appropriate .NET configuration provider. The legacy XML-based configuration system has limited support in modern .NET.

### 7. Verify Output Artifacts
After a successful Release build, inspect the output directory (`bin/Release/net8.0/` or equivalent) to confirm:
- The expected assemblies are present.
- No unintended `.dll` files from legacy references are included.
- Any publish profiles (`.pubxml`) have been updated to reflect the new target framework.

## Deployment Steps

### 1. Publish the Application
Use the `dotnet publish` command to produce deployment artifacts:
```bash
dotnet publish --configuration Release --output ./publish
```
For a self-contained deployment that does not require the .NET runtime on the target machine:
```bash
dotnet publish --configuration Release --self-contained true --runtime win-x64 --output ./publish
```
Replace `win-x64` with the appropriate runtime identifier (RID) for your target environment (e.g., `linux-x64`, `osx-x64`).

### 2. Verify the Published Output
Run the published output locally before deploying to a target environment:
```bash
./publish/AdoCore.exe   # Windows
./publish/AdoCore       # Linux/macOS
```
Confirm the application starts and behaves as expected.

### 3. Deploy to Target Environment
Copy the contents of the `./publish` directory to the target server or environment using your standard file transfer process. Ensure the target machine has the correct .NET runtime installed if you are not using a self-contained deployment. The required runtime can be downloaded from [https://dotnet.microsoft.com/download](https://dotnet.microsoft.com/download).