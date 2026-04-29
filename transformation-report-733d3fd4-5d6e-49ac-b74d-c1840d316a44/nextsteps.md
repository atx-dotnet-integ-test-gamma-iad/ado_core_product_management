# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

### 2. Restore NuGet Packages
Run the following command from the solution root to ensure all dependencies are restored cleanly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated or unlisted packages and consider updating them.

### 3. Build the Solution
Perform a full build to confirm there are no issues:

```bash
dotnet build --configuration Release
```

### 4. Run the Test Suite
If the solution contains test projects, execute them to verify runtime behavior has not regressed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as they may indicate behavioral differences between the legacy .NET Framework runtime and the new cross-platform .NET runtime.

### 5. Check for Runtime-Only Issues
Some issues do not surface at build time. Pay attention to the following areas that commonly differ between .NET Framework and modern .NET:

- **`System.Configuration`**: `ConfigurationManager` requires the `System.Configuration.ConfigurationManager` NuGet package on cross-platform .NET.
- **WCF**: Full WCF server-side hosting is not supported. Only the client-side `System.ServiceModel` packages are available via CoreWCF or community packages.
- **Reflection and serialization**: Behavior differences exist in `BinaryFormatter` (now obsolete/disabled) and certain reflection APIs.
- **Windows-specific APIs**: Any P/Invoke calls or APIs decorated with `[SupportedOSPlatform("windows")]` will not function on Linux or macOS.
- **`AppDomain`**: Some `AppDomain` members are no-ops or throw `PlatformNotSupportedException` on cross-platform .NET.

### 6. Audit NuGet Package Compatibility
Run the following to check for any packages that may not be fully compatible with the target framework:

```bash
dotnet list package --outdated
dotnet list package --deprecated
```

Update packages where appropriate.

### 7. Run on Target Platform
If the goal is to run on Linux or macOS, execute the application on that platform directly to catch any OS-specific runtime failures that would not appear on Windows.

```bash
dotnet run --configuration Release
```

### 8. Review Warnings
Even without errors, the build may have produced warnings. Review them with:

```bash
dotnet build --configuration Release /warnaserror
```

Address any warnings that could indicate future compatibility or correctness issues.

## Deployment

### 1. Publish a Self-Contained or Framework-Dependent Binary
To publish for a specific target platform, use:

```bash
# Framework-dependent (requires .NET runtime installed on target machine)
dotnet publish --configuration Release --output ./publish

# Self-contained (includes the runtime)
dotnet publish --configuration Release --self-contained true --runtime linux-x64 --output ./publish
```

### 2. Verify the Published Output
Navigate to the `./publish` directory and confirm all expected files are present, then run the published binary directly to validate it operates correctly outside of the development environment.

### 3. Review Configuration Files
Ensure any `appsettings.json`, environment variables, or other configuration sources are correctly set up for the target deployment environment, particularly if the legacy project previously relied on `app.config` or `web.config`.