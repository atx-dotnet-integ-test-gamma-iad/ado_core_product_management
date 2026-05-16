# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy the migrated project.

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

Address any warnings that surface during this step, particularly those related to nullable reference types or platform compatibility, as these can indicate latent issues.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that behavior has not changed during the migration:

```bash
dotnet test --configuration Release
```

Review test output carefully. Any failing tests should be investigated before proceeding further.

## 4. Verify Target Framework

Open each `.csproj` file and confirm that the `<TargetFramework>` element is set to the intended cross-platform version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net472` or other Windows-only framework monikers unless that is intentional.

## 5. Check for Platform-Specific API Usage

Use the .NET Upgrade Assistant or the `Microsoft.DotNet.PlatformAbstractions` compatibility analyzer to scan for any remaining Windows-specific API calls that may not have been flagged at compile time but would fail at runtime on non-Windows platforms.

```bash
dotnet tool install -g dotnet-platform-compat
```

Pay particular attention to areas such as the registry, COM interop, and Windows-specific I/O paths.

## 6. Run the Application and Perform Smoke Testing

Execute the application manually and walk through its primary workflows to confirm runtime behavior is consistent with the legacy version:

```bash
dotnet run --project ./AdoCore/AdoCore.csproj --configuration Release
```

Compare outputs and behavior against the original .NET Framework version where possible.

## 7. Review Configuration Files

Ensure that any `app.config` or `web.config` files have been properly migrated to `appsettings.json` or the appropriate .NET configuration model. Verify that connection strings, logging settings, and environment-specific values are correctly represented.

## 8. Publish the Application

Once validation is complete, publish the application for the target environment:

```bash
dotnet publish --configuration Release --output ./publish
```

If targeting a specific runtime, include the runtime identifier:

```bash
dotnet publish --configuration Release -r linux-x64 --self-contained false --output ./publish
```

Review the contents of the output directory to confirm all required assemblies and configuration files are present before deploying to the target environment.