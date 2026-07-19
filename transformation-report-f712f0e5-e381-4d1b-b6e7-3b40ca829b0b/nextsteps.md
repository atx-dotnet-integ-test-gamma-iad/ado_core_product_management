# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the target framework moniker (TFM) is set to your intended cross-platform target, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this aligns with the .NET version you intend to support.

## 2. Restore NuGet Packages

Run the following command from the solution root to confirm all dependencies resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated or incompatible packages.

## 3. Build the Solution

Perform a clean build to confirm there are no errors or warnings that were not caught previously:

```bash
dotnet build --configuration Release
```

Address any warnings that may indicate runtime issues, such as nullable reference warnings or obsolete API usage.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify existing functionality has not regressed:

```bash
dotnet test --configuration Release
```

Review the test output and ensure all previously passing tests continue to pass.

## 5. Validate Platform-Specific Behavior

Since this is a cross-platform migration, run the application on each target operating system (Windows, Linux, macOS) where applicable. Pay particular attention to:

- File path separators (`\` vs `/`)
- Case sensitivity in file system operations
- Any calls to Windows-specific APIs (registry access, COM interop, etc.) that may have been carried over

## 6. Check for Removed or Changed APIs

Use the .NET Upgrade Assistant compatibility analyzer or review the [.NET API compatibility documentation](https://learn.microsoft.com/en-us/dotnet/core/compatibility/) to confirm that no APIs used in `AdoCore` have been removed or had breaking changes in the target .NET version.

You can also run the following to get a compatibility report:

```bash
dotnet-compatibility analyze --assembly ./bin/Release/net8.0/AdoCore.dll
```

## 7. Review Database Connectivity (ADO Specific)

Given the project name `AdoCore`, it likely involves ADO.NET data access. Verify the following:

- Connection strings are correctly configured for the target environment
- Any `System.Data` usage is compatible with the target framework
- Database drivers (e.g., `Microsoft.Data.SqlClient`, `Npgsql`) are referencing current, cross-platform compatible NuGet packages rather than legacy framework assemblies

## 8. Publish the Application

Once validation is complete, publish the application for your target runtime:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Replace `linux-x64` with your intended runtime identifier (e.g., `win-x64`, `osx-x64`). Review the publish output directory to confirm all required files are present.