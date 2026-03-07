# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Restore Dependencies

Run the following command from the solution root to ensure all NuGet packages are properly restored:

```bash
dotnet restore
```

Review the output for any warnings related to package compatibility or deprecated packages targeting older frameworks.

## 2. Build the Solution

Perform a full solution build to confirm the absence of errors in a clean build environment:

```bash
dotnet build --configuration Release
```

Address any warnings that surface during this step, particularly those related to nullable reference types or platform compatibility analyzers, as these can indicate subtle issues introduced during migration.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that behavior has not changed after migration:

```bash
dotnet test --configuration Release
```

Review test output carefully. A passing build does not guarantee runtime correctness, so test coverage is important at this stage.

## 4. Verify Target Framework

Open each `.csproj` file and confirm the `<TargetFramework>` element is set to the intended .NET version (e.g., `net8.0`). Ensure consistency across all projects in the solution.

## 5. Check for Removed or Changed APIs

Run the .NET Upgrade Assistant compatibility analyzer or the platform compatibility analyzer to identify any API usage that may behave differently on cross-platform .NET compared to .NET Framework:

```bash
dotnet add package Microsoft.DotNet.PlatformAbstractions
```

Pay particular attention to:
- `System.Configuration` usage
- Windows Registry access
- `System.Drawing` (now requires `System.Drawing.Common` with platform restrictions)
- WCF or Remoting dependencies

## 6. Test on Target Platforms

If cross-platform support is a goal, run and validate the application on each intended operating system (Windows, Linux, macOS) to catch any platform-specific runtime issues that would not appear during a Windows-only build.

## 7. Review Runtime Configuration Files

Check for the presence and correctness of the following files:
- `appsettings.json` (replacing `App.config` or `Web.config` where applicable)
- `runtimeconfig.json`
- Any environment-specific configuration files

## 8. Publish the Application

Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

For a self-contained deployment targeting a specific runtime, use:

```bash
dotnet publish --configuration Release --runtime win-x64 --self-contained true --output ./publish
```

Replace `win-x64` with the appropriate runtime identifier for your target environment (e.g., `linux-x64`, `osx-x64`).

## 9. Validate the Published Output

Run the published output directly from the `./publish` directory to confirm it executes correctly outside of the development environment before distributing or deploying it.