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
Perform a clean build to confirm there are no errors or warnings that may have been suppressed:

```bash
dotnet build --configuration Release
```

Address any warnings that could indicate runtime issues, such as nullable reference warnings or platform compatibility warnings.

### 4. Run Existing Tests
If the solution contains test projects, execute them to verify existing functionality has not regressed:

```bash
dotnet test --configuration Release
```

Review test output and ensure all previously passing tests continue to pass.

### 5. Check for Platform-Specific API Usage
Use the .NET Upgrade Assistant or the `Microsoft.DotNet.PlatformAbstractions` compatibility analyzer to scan for any remaining Windows-specific API calls that may compile successfully but fail at runtime on non-Windows platforms:

```bash
dotnet add package Microsoft.Windows.Compatibility
```

Alternatively, run a static analysis pass using:

```bash
dotnet build /p:EnableNETAnalyzers=true
```

### 6. Run the Application on Target Platforms
Execute the application on each platform you intend to support (Windows, Linux, macOS) and verify runtime behavior is consistent:

```bash
dotnet run --configuration Release
```

Pay particular attention to file path handling, environment variable access, and any registry or Windows-specific service calls.

### 7. Review Output Artifacts
Publish the application and inspect the output to confirm the correct runtime and dependencies are bundled:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true
```

Adjust the `--runtime` flag to match your deployment targets.

### 8. Validate Configuration Files
Check that `appsettings.json`, `web.config` (if applicable), or any other configuration files have been updated to reflect the new hosting and runtime model. Remove any IIS-specific or legacy .NET Framework configuration sections that are no longer applicable.