# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are steps to validate and test the migrated project before deploying it.

## 1. Verify Target Framework

Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element references the intended cross-platform .NET version (e.g., `net8.0`). Example:

```xml
<PropertyGroup>
  <TargetFramework>net8.0</TargetFramework>
</PropertyGroup>
```

## 2. Restore Dependencies

Run the following command from the solution root to ensure all NuGet packages are restored correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated or unlisted packages and consider updating them.

## 3. Build the Solution

Perform a full build to confirm there are no errors or warnings that may have been missed:

```bash
dotnet build --configuration Release
```

Address any warnings that could indicate runtime issues, such as nullable reference warnings or obsolete API usage.

## 4. Run the Test Suite

If the solution contains test projects, execute all tests to verify that existing functionality has not regressed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review test output carefully. Any failing tests should be investigated to determine if they are caused by behavioral differences between the legacy .NET Framework and the new cross-platform .NET runtime.

## 5. Check for Platform-Specific API Usage

Use the .NET Upgrade Assistant compatibility analyzer or the `Microsoft.DotNet.PlatformAbstractions` tooling to identify any remaining calls to Windows-only APIs (e.g., registry access, `System.Drawing`, WCF server-side components). Replace or conditionally compile these as needed.

You can also run the API compatibility tool:

```bash
dotnet tool install -g Microsoft.DotNet.ApiCompat
```

## 6. Validate Runtime Behavior

Run the application locally on each target platform (Windows, Linux, macOS) if cross-platform support is a requirement. Pay particular attention to:

- File path separators (`\` vs `/`)
- Case sensitivity in file system operations
- Culture and encoding differences
- Any use of `AppDomain` or reflection that may behave differently

## 7. Review Configuration Files

Ensure that any `app.config` or `web.config` files have been migrated to `appsettings.json` or the appropriate .NET configuration model. Confirm that connection strings, logging settings, and environment-specific values are correctly defined.

## 8. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your target environment:

```bash
dotnet publish --configuration Release --runtime win-x64 --self-contained false
```

Replace `win-x64` with the appropriate runtime identifier (e.g., `linux-x64`, `osx-x64`) based on your deployment target. Review the contents of the `publish` output folder before deploying to confirm all required files are present.