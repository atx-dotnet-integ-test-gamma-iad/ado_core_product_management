# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version (e.g., `net8.0` or `net6.0`).

```xml
<PropertyGroup>
  <TargetFramework>net8.0</TargetFramework>
</PropertyGroup>
```

## 2. Restore and Build Locally

Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Ensure there are no warnings that could indicate deprecated APIs or packages that may cause runtime issues.

## 3. Run Existing Tests

If a test project exists in the solution, execute the test suite to verify runtime behavior matches expectations:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and address logic or compatibility issues that may not have surfaced as build errors.

## 4. Check for Platform-Specific API Usage

Even without build errors, some APIs may have been available in .NET Framework but behave differently or throw `PlatformNotSupportedException` at runtime on non-Windows platforms. Review usage of the following common problem areas:

- `System.Drawing` (use `System.Drawing.Common` NuGet package or migrate to a cross-platform alternative)
- `Microsoft.Win32.Registry`
- `System.Security.Permissions`
- WCF server-side components
- `AppDomain.CreateDomain`

Run the application on each target platform (Windows, Linux, macOS) if cross-platform support is a requirement.

## 5. Review NuGet Package Compatibility

Check that all NuGet packages referenced in `AdoCore.csproj` are compatible with the target framework. Use the following command to identify outdated or incompatible packages:

```bash
dotnet list package --outdated
dotnet list package --deprecated
```

Update packages where necessary using:

```bash
dotnet add package <PackageName> --version <LatestVersion>
```

## 6. Validate Configuration Files

If the project previously used `App.config` or `Web.config`, confirm that settings have been migrated to `appsettings.json` or environment variables where appropriate, as `System.Configuration.ConfigurationManager` has limited support in cross-platform .NET.

## 7. Perform Runtime Validation

Run the application and exercise all major code paths. Pay particular attention to:

- Database connectivity (ADO.NET drivers, connection strings)
- File I/O paths (avoid hardcoded Windows-style paths)
- Reflection-based code
- Serialization and deserialization logic

## 8. Publish the Application

Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

For a self-contained deployment targeting a specific runtime:

```bash
dotnet publish --configuration Release --runtime win-x64 --self-contained true --output ./publish/win-x64
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish/linux-x64
```

Review the contents of the publish output directory to confirm all required assets and dependencies are present before deploying to the target environment.