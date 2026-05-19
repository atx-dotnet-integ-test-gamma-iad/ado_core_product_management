# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects still reference `net4x` or `netstandard` targets unless explicitly required.

### 2. Restore Dependencies
Run the following command from the solution root to confirm all NuGet packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or unresolved dependencies.

### 3. Build the Solution
Perform a full build to confirm there are no errors or warnings that may have been suppressed during transformation:

```bash
dotnet build --configuration Release
```

Address any warnings that could indicate runtime issues, such as nullable reference warnings or obsolete API usage.

### 4. Run Existing Tests
If the solution contains test projects, execute them to verify that existing behavior has been preserved:

```bash
dotnet test --configuration Release
```

Review test results carefully. Failing tests after a migration often indicate behavioral differences between .NET Framework and cross-platform .NET, particularly around:
- `System.Configuration` usage
- Windows-specific APIs
- Reflection behavior differences
- Encoding and globalization defaults

### 5. Check for Platform-Specific API Usage
Use the .NET Compatibility Analyzer to identify any remaining Windows-specific API calls that may compile successfully but fail at runtime on non-Windows platforms:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
```

Review any `CA1416` platform compatibility warnings that appear after adding the analyzer.

### 6. Review `App.config` / `Web.config` Migration
If the original project used `App.config` or `Web.config`, confirm that configuration has been migrated appropriately to `appsettings.json` or another supported mechanism, as `System.Configuration.ConfigurationManager` behavior differs in cross-platform .NET.

### 7. Verify Runtime Behavior
Run the application manually and exercise its primary workflows. Pay particular attention to:
- File path handling (use `Path.Combine` rather than hardcoded separators)
- Culture-sensitive operations
- Any use of `AppDomain`, `Thread.Abort`, or remoting APIs that are not fully supported in cross-platform .NET

### 8. Publish the Application
Once validation is complete, publish a release build targeting your intended runtime:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true
```

Replace `linux-x64` with your target runtime identifier (e.g., `win-x64`, `osx-x64`) as appropriate. Review the publish output directory to confirm all required assets are present.