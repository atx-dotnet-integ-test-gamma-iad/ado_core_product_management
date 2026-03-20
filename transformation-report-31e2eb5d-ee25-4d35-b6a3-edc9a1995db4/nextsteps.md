# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Restore Dependencies

Run the following command from the solution root to ensure all NuGet packages are properly restored:

```bash
dotnet restore
```

Review the output for any warnings related to package compatibility or deprecated packages targeting older frameworks.

## 2. Build the Solution

Perform a full solution build to confirm the absence of errors in a clean build context:

```bash
dotnet build --configuration Release
```

Address any warnings that surface during this step, particularly those related to nullable reference types or platform compatibility analyzers, as these can indicate latent issues.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that behavior has not changed during migration:

```bash
dotnet test --configuration Release
```

Review test output carefully. A passing build does not guarantee functional correctness, so test coverage is important at this stage.

## 4. Verify Target Framework

Open each `.csproj` file and confirm the `<TargetFramework>` element reflects the intended cross-platform .NET version (e.g., `net8.0`). Example:

```xml
<PropertyGroup>
  <TargetFramework>net8.0</TargetFramework>
</PropertyGroup>
```

## 5. Check for Platform-Specific API Usage

Use the .NET Compatibility Analyzer to identify any remaining Windows-specific or platform-specific API calls that may cause runtime failures on non-Windows systems:

```bash
dotnet build /p:PlatformTarget=AnyCPU
```

Look for `CA1416` analyzer warnings, which flag platform-specific API usage.

## 6. Review Configuration Files

Ensure that any `App.config` or `Web.config` files have been migrated to `appsettings.json` or the appropriate .NET configuration model. Legacy configuration files are not fully supported in cross-platform .NET.

## 7. Test on Target Platforms

Run the application on each platform you intend to support (e.g., Linux, macOS, Windows) to catch any runtime issues that static analysis may not surface:

```bash
dotnet run --configuration Release
```

## 8. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your target environment:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true
```

Replace `linux-x64` with the appropriate runtime identifier for your deployment target (e.g., `win-x64`, `osx-x64`). Review the publish output directory to confirm all required files are present.

## 9. Review Output Assemblies

Confirm that the output assemblies in the `bin/Release` directory match expectations in terms of structure and included dependencies, particularly if the legacy project relied on specific assembly references that may have changed during migration.