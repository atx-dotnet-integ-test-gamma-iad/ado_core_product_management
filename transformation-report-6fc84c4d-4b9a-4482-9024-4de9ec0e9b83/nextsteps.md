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

Address any warnings that surface, particularly those related to nullable reference types or obsolete APIs, as these can indicate latent issues.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that behavior has not changed during the migration:

```bash
dotnet test --configuration Release
```

Review test output carefully. A passing build does not guarantee correct runtime behavior, so test coverage is critical at this stage.

## 4. Validate Target Framework

Open each `.csproj` file and confirm the `<TargetFramework>` element is set to the intended version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure all projects in the solution are targeting a consistent and supported framework version.

## 5. Check for Removed or Changed APIs

Run the .NET Upgrade Assistant compatibility analyzer or use the `Microsoft.DotNet.ApiCompat` tooling to identify any API usage that may behave differently on cross-platform .NET compared to .NET Framework:

```bash
dotnet tool install -g dotnet-apicompat
```

Pay particular attention to areas such as:
- `System.Configuration`
- `System.Web`
- Windows Registry access
- File path handling (case sensitivity on Linux/macOS)

## 6. Test on Target Platforms

If cross-platform support is a goal, run and test the application on each intended operating system (Windows, Linux, macOS) to catch platform-specific runtime issues that would not appear during a build.

## 7. Review Runtime Configuration Files

Check that `appsettings.json`, `runtimeconfig.json`, or any other configuration files are present and correctly structured for the new hosting model. If the project previously relied on `app.config` or `web.config`, confirm those values have been migrated appropriately.

## 8. Publish the Application

Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

For a self-contained deployment that does not require the .NET runtime to be installed on the target machine:

```bash
dotnet publish --configuration Release --runtime win-x64 --self-contained true --output ./publish
```

Replace `win-x64` with the appropriate runtime identifier for your target environment (e.g., `linux-x64`, `osx-x64`).