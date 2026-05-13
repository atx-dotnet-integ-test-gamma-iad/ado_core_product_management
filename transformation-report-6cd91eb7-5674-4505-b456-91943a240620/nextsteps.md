# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48` or other legacy .NET Framework monikers unless that is intentional for multi-targeting.

### 2. Restore Dependencies
Run the following command from the solution root to confirm all NuGet packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that do not support the target framework.

### 3. Build the Solution
Perform a clean build to confirm there are no warnings that may indicate runtime issues:

```bash
dotnet build --configuration Release
```

Address any warnings related to nullable reference types, obsolete APIs, or platform compatibility.

### 4. Run the Test Suite
If the solution contains test projects, execute all tests to verify functional correctness after the transformation:

```bash
dotnet test --configuration Release
```

Review any failing tests and determine whether failures are caused by the migration or pre-existing issues.

### 5. Check for Platform-Specific API Usage
Use the .NET Compatibility Analyzer or review the build output for `CA1416` warnings, which indicate calls to APIs that are only supported on specific platforms (e.g., Windows-only APIs). If the project is intended to run cross-platform, these usages will need to be guarded or replaced.

### 6. Review `App.config` / `Web.config` Usage
Legacy configuration files are not used in cross-platform .NET. Confirm that any configuration has been migrated to `appsettings.json` and that `Microsoft.Extensions.Configuration` is being used where applicable.

### 7. Verify Runtime Behavior
Run the application locally on the target platform(s) — for example, Linux or macOS if cross-platform support is a goal — and confirm the application starts and behaves as expected:

```bash
dotnet run --project ./AdoCore/AdoCore.csproj --configuration Release
```

### 8. Publish a Self-Contained Build
Produce a release build targeting the intended runtime to confirm the output is complete and functional:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true
```

Adjust the `--runtime` identifier as appropriate for your deployment target (e.g., `win-x64`, `osx-x64`).