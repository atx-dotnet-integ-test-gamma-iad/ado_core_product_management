# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Restore Dependencies

Run the following command to ensure all NuGet packages are properly restored:

```bash
dotnet restore
```

Review the output for any warnings related to package compatibility or deprecated packages targeting older frameworks.

## 2. Build the Solution

Perform a full solution build to confirm the error-free state is consistent across all configurations:

```bash
dotnet build --configuration Debug
dotnet build --configuration Release
```

Address any warnings that appear, particularly those related to nullable reference types or obsolete APIs, as these can indicate latent issues.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify runtime behavior matches expectations from the legacy project:

```bash
dotnet test --configuration Release
```

Review test results carefully. A passing build does not guarantee correct runtime behavior, especially after a cross-platform migration.

## 4. Verify Platform-Specific Behavior

Cross-platform migrations can introduce subtle runtime differences. Manually verify the following:

- **File paths**: Ensure no hardcoded Windows-style paths (e.g., `C:\`) remain in the code or configuration files.
- **Line endings**: Confirm that any file I/O operations handle both `\r\n` and `\n` correctly.
- **Case sensitivity**: Linux file systems are case-sensitive. Verify that all file and directory references use consistent casing.
- **Registry and Windows APIs**: Search the codebase for any remaining calls to `Microsoft.Win32` or `System.Windows` namespaces that may not be supported cross-platform.

## 5. Review Target Framework

Open each `.csproj` file and confirm the `<TargetFramework>` element is set to the intended modern .NET version (e.g., `net8.0`):

```xml
<TargetFramework>net8.0</TargetFramework>
```

If any projects still reference `net48` or `netstandard2.0`, evaluate whether they need to be updated.

## 6. Check for Removed or Changed APIs

Some APIs available in .NET Framework are not present or behave differently in modern .NET. Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` tooling to scan for any remaining compatibility concerns:

```bash
dotnet tool install -g upgrade-assistant
upgrade-assistant analyze <solution>.sln
```

## 7. Test on Target Platforms

Run the application on each platform you intend to support (Windows, Linux, macOS) and verify that behavior is consistent. Pay particular attention to:

- Authentication and identity components
- Database connection strings and drivers
- Configuration file loading (`appsettings.json` vs. legacy `app.config`/`web.config`)

## 8. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your target environment:

```bash
# Framework-dependent deployment
dotnet publish --configuration Release

# Self-contained deployment for a specific platform
dotnet publish --configuration Release --runtime linux-x64 --self-contained true
```

Review the output directory to confirm all required assets and configuration files are present before deploying to the target environment.