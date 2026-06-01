# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the target framework moniker (TFM) is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this aligns with the .NET version installed on your machine by running:

```bash
dotnet --version
```

## 2. Restore Dependencies

Run a NuGet restore to confirm all packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that do not support the target framework. Replace any packages that only support .NET Framework with their cross-platform equivalents if warnings are present.

## 3. Build the Solution

Perform a clean build to confirm there are no compilation issues:

```bash
dotnet build --configuration Release
```

Review the output and resolve any warnings that could indicate runtime issues, such as nullable reference warnings or platform compatibility warnings.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify that existing functionality has not regressed:

```bash
dotnet test --configuration Release
```

Review test results and investigate any failures. Pay particular attention to tests that exercise platform-specific behavior, file I/O, or database connectivity, as these areas are most likely to surface issues after a cross-platform migration.

## 5. Validate Platform-Specific Code

Search the codebase for APIs that may behave differently across operating systems:

- **File paths**: Ensure `Path.Combine` is used instead of hardcoded path separators.
- **Registry access**: `Microsoft.Win32.Registry` is Windows-only. If the project uses it, consider abstracting it behind a platform check or replacing it with a cross-platform configuration mechanism such as `Microsoft.Extensions.Configuration`.
- **Windows-specific P/Invoke calls**: Search for `[DllImport]` attributes and verify the referenced native libraries are available on all target platforms.
- **`Environment.SpecialFolder`**: Verify that any special folder paths used are valid on the target operating system.

## 6. Test on Target Platforms

If the goal is to run on non-Windows platforms, test the application on those platforms explicitly:

```bash
dotnet run --configuration Release
```

Run this on each target operating system (Linux, macOS) and observe any runtime exceptions that did not appear during the Windows build.

## 7. Review NuGet Package Compatibility

Check that all NuGet packages in `AdoCore.csproj` are compatible with the target framework. You can use the following command to inspect the resolved packages:

```bash
dotnet list package
```

Use the `--outdated` flag to identify packages that have newer versions available:

```bash
dotnet list package --outdated
```

## 8. Publish the Application

Once validation is complete, publish the application for the target runtime. For a self-contained deployment targeting Linux x64 as an example:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true
```

For a framework-dependent deployment:

```bash
dotnet publish --configuration Release
```

The output will be placed in the `bin/Release/<tfm>/publish/` directory. Verify the published output runs correctly in the target environment before distributing it.