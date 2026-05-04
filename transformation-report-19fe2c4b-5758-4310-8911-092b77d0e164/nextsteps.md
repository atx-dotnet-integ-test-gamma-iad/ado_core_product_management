# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended .NET version (e.g., `net8.0` or `net6.0`). For example:

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

Review the output for any warnings that may indicate deprecated APIs or packages that could cause runtime issues even if they do not produce build errors.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that existing functionality is preserved:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as they may indicate behavioral differences between the legacy .NET Framework runtime and the new cross-platform .NET runtime.

## 4. Check for Runtime Compatibility Issues

Even with a clean build, certain APIs behave differently on cross-platform .NET. Pay attention to the following areas:

- **Windows-specific APIs**: Any usage of `System.Windows.Forms`, `System.Drawing`, or COM interop will not work on non-Windows platforms unless appropriate compatibility packages (e.g., `Microsoft.Windows.Compatibility`) are referenced.
- **Configuration**: `System.Configuration.ConfigurationManager` requires the `System.Configuration.ConfigurationManager` NuGet package on .NET Core/.NET 5+.
- **AppDomain**: Some `AppDomain` members are not supported and will throw `PlatformNotSupportedException` at runtime.
- **Reflection and serialization**: Binary serialization (`BinaryFormatter`) is disabled by default in modern .NET and should be replaced.

## 5. Review NuGet Package Versions

Open the `.csproj` file and check that all NuGet package references are targeting versions compatible with your chosen target framework. You can use the following command to identify outdated packages:

```bash
dotnet list package --outdated
```

Update packages where appropriate, taking care to review changelogs for breaking changes.

## 6. Validate Platform-Specific Behavior

If the application is intended to run on Linux or macOS in addition to Windows, perform a test run on each target platform to surface any platform-specific runtime exceptions.

## 7. Publish the Application

Once validation is complete, publish the application using the following command, adjusting the runtime identifier (`-r`) as needed:

```bash
dotnet publish --configuration Release --runtime win-x64 --self-contained false --output ./publish
```

For a self-contained deployment that includes the .NET runtime:

```bash
dotnet publish --configuration Release --runtime win-x64 --self-contained true --output ./publish
```

Review the contents of the `./publish` directory to confirm all expected files are present before deploying to the target environment.