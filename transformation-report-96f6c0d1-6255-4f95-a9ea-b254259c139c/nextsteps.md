# Next Steps

The transformation appears to have completed successfully. There are no build errors reported across any of the projects in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48` or any other legacy .NET Framework moniker unless that is intentional for multi-targeting.

## 2. Restore NuGet Packages

Run the following command from the solution root to ensure all dependencies resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or version conflicts and update them as needed using:

```bash
dotnet list package --outdated
```

## 3. Build the Solution

Perform a full build to confirm there are no compilation issues:

```bash
dotnet build --configuration Release
```

Address any warnings that surface during the build, particularly those related to nullable reference types or platform compatibility (e.g., `CA1416`).

## 4. Run the Test Suite

If the solution contains test projects, execute all tests to verify behavioral correctness after migration:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as they may indicate runtime behavioral differences between .NET Framework and modern .NET.

## 5. Check for Platform-Specific API Usage

Use the .NET Compatibility Analyzer to identify any APIs that may not be available cross-platform. Run the following and review the output:

```bash
dotnet build --configuration Release /p:EnableNETAnalyzers=true
```

Pay particular attention to warnings prefixed with `CA1416` (platform compatibility) and `SYSLIB` (obsoleted or replaced APIs).

## 6. Validate Runtime Behavior

Run the application directly and exercise its primary workflows:

```bash
dotnet run --project <YourStartupProject>.csproj --configuration Release
```

Compare the output and behavior against the known behavior of the original .NET Framework version to identify any regressions.

## 7. Review Configuration Files

- Confirm that `app.config` or `web.config` settings have been migrated to `appsettings.json` or environment-based configuration where applicable.
- Verify that any connection strings, feature flags, or environment-specific values are correctly represented in the new configuration system.

## 8. Check for Removed or Changed APIs

Review the following common migration pain points that may only surface at runtime rather than at compile time:

- `BinaryFormatter` usage (removed in .NET 9, disabled by default in .NET 5+)
- `AppDomain` APIs with limited cross-platform support
- `System.Drawing` on non-Windows platforms (requires `System.Drawing.Common` and is Windows-only in .NET 6+)
- WCF server-side components (not supported in modern .NET; consider CoreWCF as a replacement)

## 9. Publish the Application

Once validation is complete, publish the application for your target environment:

```bash
dotnet publish --configuration Release --output ./publish
```

For a self-contained deployment that does not require the .NET runtime to be installed on the target machine:

```bash
dotnet publish --configuration Release --self-contained true --runtime <rid> --output ./publish
```

Replace `<rid>` with the appropriate Runtime Identifier, such as `win-x64`, `linux-x64`, or `osx-x64`.