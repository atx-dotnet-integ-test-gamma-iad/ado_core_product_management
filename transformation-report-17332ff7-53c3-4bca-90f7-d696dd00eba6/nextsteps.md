# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Restore Dependencies

Run the following command from the solution root to ensure all NuGet packages are properly restored:

```bash
dotnet restore
```

Review the output for any warnings related to package compatibility or deprecated packages targeting older frameworks.

## 2. Build the Solution

Perform a full solution build to confirm there are no issues beyond what was captured in the initial error report:

```bash
dotnet build --configuration Release
```

Address any warnings that may surface, particularly those related to nullable reference types or platform compatibility analyzers (CA1416, etc.), as these can indicate runtime issues on specific platforms.

## 3. Run Unit Tests

If the solution contains test projects, execute them to verify that existing functionality has not regressed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Pay close attention to any tests that exercise platform-specific behavior, file I/O paths, or Windows-specific APIs, as these are common sources of failure after a cross-platform migration.

## 4. Verify Target Framework

Open each `.csproj` file and confirm the `<TargetFramework>` element is set to the intended version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

If cross-platform support is required, ensure no project is still targeting `net48` or another Windows-only framework moniker.

## 5. Check for Platform-Specific API Usage

Use the .NET Compatibility Analyzer to identify any remaining calls to Windows-only APIs. Build with the following property to surface these warnings explicitly:

```bash
dotnet build -p:PlatformTarget=AnyCPU
```

Review any `CA1416` warnings and either guard the code with `OperatingSystem.IsWindows()` checks or replace the APIs with cross-platform alternatives.

## 6. Review Configuration and App Settings

Confirm that any configuration files (e.g., `appsettings.json`, environment variables) have been updated to replace legacy `App.config` or `Web.config` patterns where applicable. Verify that the `Microsoft.Extensions.Configuration` setup correctly loads all expected values at runtime.

## 7. Manual Smoke Testing

Run the application locally and exercise the primary workflows to confirm runtime behavior matches the legacy version:

```bash
dotnet run --project ./AdoCore/AdoCore.csproj --configuration Release
```

Compare outputs, logs, and any database or file artifacts against the known behavior of the original .NET Framework version.

## 8. Publish the Application

Once validation is complete, publish the application for your target environment:

```bash
dotnet publish --configuration Release --output ./publish
```

For a self-contained deployment that does not require the .NET runtime to be pre-installed on the target machine:

```bash
dotnet publish --configuration Release --self-contained true --runtime win-x64 --output ./publish
```

Replace `win-x64` with the appropriate runtime identifier (e.g., `linux-x64`, `osx-x64`) based on your deployment target.